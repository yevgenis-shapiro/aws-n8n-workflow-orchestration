#!/usr/bin/env bash

COMMAND="$1"
SUITE_NAMESPACE="$2"
SUBDOMAIN="$3"
SUITETYPE="$4"
MULTI_NLB="$5"

PUBLIC_SUBNET_IDS=( %{ for id in public_subnet_ids ~} "${ id }" %{ endfor ~})
LOAD_BALANCER_RANGE="${ load_balancer_access_addresses }"
VPC_ID="${ vpc_id }"
REGION="${ aws_region }"
CERTIFICATE_ARN="${ certificate_arn }"
ENV_PREFIX="${ environment_prefix }"
HOSTED_ZONE="${ hosted_zone }"

SCRIPT_DIR="$(dirname $0)"
DELETE_SCRIPT_PATH="$SCRIPT_DIR/delete-load-balancers-$SUITE_NAMESPACE-$SUBDOMAIN.sh"
DELETE_SUBDOMAIN_JSON="$SCRIPT_DIR/delete-subdomain-$SUITE_NAMESPACE-$SUBDOMAIN.json"
SCHEME=$${SCHEME:-"internal"}

printUsage() {
   cat << EOF
Usage:
------
  $(basename "$0") <command> <suite_namespace> [<subdomain>] <SUITETYPE> <MULTI_NLB>

  Commands:
  ---------
  create     - Create load balancers to access CDF and suite services
  remove     - Remove the load balancers the grant access to CDF and suite services
  ---------
  MULTI_NLB   - set to "multinlb" parameter creates multi lb based on suite namespace else will create single lb
EOF
}

trackDeleteCommand() {
  command="$1"

  echo "$1" >> $DELETE_SCRIPT_PATH
}

patchK8SServices() {
  namespace="$1"
  service_name="$2"
  kubectl patch services "$service_name" \
    -p '{"metadata":{"annotations":{"service.beta.kubernetes.io/aws-load-balancer-type":"nlb","service.beta.kubernetes.io/aws-load-balancer-internal":"true"}},"spec":{"type":"LoadBalancer", "loadBalancerSourceRanges": ['"$LOAD_BALANCER_RANGE"']}}' \
    -n "$namespace"
}

getServiceExternalIp() {
  namespace="$1"
  service_name="$2"
  kubectl -n "$namespace" get svc "$service_name" -o=jsonpath="{ .status.loadBalancer.ingress[0].hostname }"
}

waitForServiceExternalIp() {
  namespace="$1"
  service_name="$2"
  retries=$${3:-20}
  delay=$${4:-5}
  for i in $(seq 1 "$retries")
  do
    if [ -n "$(getServiceExternalIp "$namespace" "$service_name")" ]
    then
      break
    fi
    sleep "$delay"
  done
}

waitForCertificate() {
  arn="$1"
  domain_name=$(aws acm describe-certificate \
	  --certificate-arn "$CERTIFICATE_ARN" \
	  --query 'Certificate.DomainName' \
	  --region "$REGION" \
	  --output text)

  status=$(aws acm describe-certificate \
	  --certificate-arn "$CERTIFICATE_ARN" \
	  --query 'Certificate.Status' \
	  --region "$REGION" \
	  --output text)

  while [ "$status" != "ISSUED" ]
  do
    echo "Waiting for certificate for domain '$domain_name' to become active. Current status: '$status'"
    sleep 10
    status=$(aws acm describe-certificate \
  	    --certificate-arn "$CERTIFICATE_ARN" \
  	    --query 'Certificate.Status' \
	    --region "$REGION" \
	    --output text)
  done
}

getLBNameByIP() {
  ip="$1"
  aws elbv2 describe-load-balancers  \
    --query "LoadBalancers[?DNSName==\`$ip\`].LoadBalancerName"  \
    --output text --region "$REGION"
}

getLBPrivateIP() {
  name="$1"
  aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=description,Values=*$${name}*" \
    --query "NetworkInterfaces[].PrivateIpAddresses[?Primary==\`true\`].PrivateIpAddress" \
    --output text --region "$REGION"
}

waitForServicePPIPs() {
  service_name="$1"
  retries=$${2:-20}
  delay=$${3:-5}
  for i in $(seq 1 "$retries")
  do
    if [ -n "$(getLBPrivateIP "$service_name")" ]
    then
      break
    fi
    sleep "$delay"
  done
}

createTargetGroup() {
  name="$1"
  protocol="$2"
  port="$3"
  vpc_id="$4"
  arn=$(aws elbv2 create-target-group \
    --name "$name" \
    --protocol "$protocol" \
    --port "$port" \
    --target-type ip \
    --vpc-id "$vpc_id" \
    --query "TargetGroups[].TargetGroupArn" \
    --output text --region "$REGION")

  trackDeleteCommand "aws elbv2 delete-target-group --target-group-arn '$arn' --region '$REGION'"

  echo "$arn"
}

registerTargetInTargetGroup() {
  target_group="$1"
  targets="$2"
  target_list=$(for target in $targets; do echo " Id=$target" | tr -d '\n'; done)
  aws elbv2 register-targets \
    --target-group-arn "$target_group" \
    --targets $target_list \
    --region "$REGION"
}

createExternalNLB() {
  name="$1"
  shift
  subnet_ids=("$@")
  arn=$(aws elbv2 create-load-balancer \
    --name "$name" \
    --subnets "$${subnet_ids[@]}" \
    --scheme "$SCHEME" \
    --type network \
    --ip-address-type ipv4 \
    --query "LoadBalancers[].LoadBalancerArn" \
    --output text --region "$REGION")

  trackDeleteCommand "aws elbv2 delete-load-balancer --load-balancer-arn '$arn' --region '$REGION'"

  echo "$arn"
}

getNLBDNSName() {
  nlb_arn="$1"
  aws elbv2 describe-load-balancers \
    --load-balancer-arns "$nlb_arn" \
    --query 'LoadBalancers[0].DNSName' \
    --output text --region "$REGION"
}

addTLSListener() {
  nlb="$1"
  port="$2"
  target_group="$3"
  arn=$(aws elbv2 create-listener \
    --load-balancer-arn "$nlb" \
    --protocol TLS \
    --port "$port" \
    --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 \
    --certificate "CertificateArn=$CERTIFICATE_ARN" \
    --default-actions Type=forward,TargetGroupArn="$target_group" \
    --query 'Listeners[0].ListenerArn' \
    --output text --region "$REGION")

  echo "$arn"
}

addListenerWithProtocol() {
  nlb="$1"
  port="$2"
  target_group="$3"
  protocol="$4"
  arn=$(aws elbv2 create-listener \
    --load-balancer-arn "$nlb" \
    --protocol "$protocol" \
    --port "$port" \
    --default-actions Type=forward,TargetGroupArn="$target_group" \
    --query 'Listeners[0].ListenerArn' \
    --output text --region "$REGION")

  echo "$arn"
}


addListenerForService() {
  external_nlb="$1"
  namespace="$2"
  service_name="$3"
  protocol="$4"    # TLS, UDP or TCP
  service_port="$5"
  external_port="$6"

  PORTS=($(grep -Eo '[[:digit:]]+' <<<"$service_port"))
  if [ $${#PORTS[@]} == 1 ]; then
    PORTS[1]=$${PORTS[0]}
  fi
  EPORTS=($(grep -Eo '[[:digit:]]+' <<<"$external_port"))
  if [ $${#EPORTS[@]} == 1 ]; then
    EPORTS[1]=$${EPORTS[0]}
  fi
  for ((service_port=$${PORTS[0]},external_port=$${EPORTS[0]};service_port<=$${PORTS[1]} && external_port<=$${EPORTS[1]};service_port++,external_port++));
  do
    service_name="$3"
    actual_svc=$(kubectl -n "$namespace" get svc "$service_name" -o "jsonpath={.metadata.name}" 2> /dev/null)
    if [ "$actual_svc" != "$service_name" ]
    then
      echo -e "Service '$service_name' not (yet) present. Skipping."
      return 1
    fi
    
    echo "Creating load balancer listener for service '$service_name'"
    
    patchK8SServices "$namespace" "$service_name"
    echo -e "\tPatched K8S service"
    waitForServiceExternalIp "$namespace" "$service_name"
    
    service_lb_ip=$(getServiceExternalIp "$namespace" "$service_name")
    echo -e "\tService load balancer IP/hostname: $service_lb_ip"
    
    service_lb_name=$(getLBNameByIP "$service_lb_ip")
    echo -e "\tService load balancer name: $service_lb_name"
    
    waitForServicePPIPs "$service_lb_name"
    service_lb_ppips=$(getLBPrivateIP "$service_lb_name")
    service_tg=$(createTargetGroup "$ENV_PREFIX-$SUITE_NAMESPACE-tg-$protocol-$service_port" "$protocol" "$service_port" "$VPC_ID")
    echo -e "\tCreated target group: $service_tg"
    
    registerTargetInTargetGroup "$service_tg" "$service_lb_ppips"
    
    if [ "$protocol" == "TLS" ]
    then
      listener_arn=$(addTLSListener "$external_nlb" "$external_port" "$service_tg")
      echo -e "\tService '$service_name' now exposed on NLB '$external_nlb' via port '$external_port'"
    elif [ "$protocol" == "TCP" -o "$protocol" == "UDP" ]
    then
      listener_arn=$(addListenerWithProtocol "$external_nlb" "$external_port" "$service_tg" "$protocol" )
      echo -e "\tService '$service_name' now exposed on NLB '$external_nlb' via port '$external_port'"
    else
      echo "Unknown protocol: '$protocol'. Only TCP , UDP and TLS are supported."
    fi
  done
}

getHostedZoneName() {
  id="$1"
  aws route53 get-hosted-zone \
    --id "$id" --query 'HostedZone.Name' \
    --output text --region "$REGION"
}

addSubdomain() {
  nlb_name="$1"
  hosted_zone_id="$2"
  hosted_zone_name="$3"
  subdomain_name="$4"
  tmpfile="$(mktemp)"
  cat <<EOF > $tmpfile
{
  "Comment": "Suite entry point",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$subdomain_name.$hosted_zone_name",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{ "Value": "$nlb_name" }]
    }
  }]
}
EOF

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$hosted_zone_id" \
    --change-batch file://$tmpfile \
    --region "$REGION" > /dev/null

  cat <<EOF > $DELETE_SUBDOMAIN_JSON
{
  "Comment": "Suite entry point",
  "Changes": [{
    "Action": "DELETE",
    "ResourceRecordSet": {
      "Name": "$subdomain_name.$hosted_zone_name",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{ "Value": "$nlb_name" }]
    }
  }]
}
EOF

  trackDeleteCommand "aws route53 change-resource-record-sets --hosted-zone-id \"$hosted_zone_id\" --change-batch file://$DELETE_SUBDOMAIN_JSON --region \"$REGION\" > /dev/null"
}

createLoadBalancers() {
  echo "Allowing access for: $${LOAD_BALANCER_RANGE}"

  if  [ "$MULTI_NLB" = "multinlb" ] ; then
        external_nlb=$(createExternalNLB "$ENV_PREFIX-$SUITE_NAMESPACE-nlb" "$${PUBLIC_SUBNET_IDS[@]}")
  else
        external_nlb=$(createExternalNLB "$ENV_PREFIX-nlb" "$${PUBLIC_SUBNET_IDS[@]}")
  fi
  
  waitForCertificate "$CERTIFICATE_ARN" || exit 1

  SUITETYPE=$${SUITETYPE,,}
 
  if [ -f $SCRIPT_DIR/rules_$SUITETYPE.sh ];then
          . $SCRIPT_DIR/rules_$SUITETYPE.sh
  else
          echo "kindly enter correct suitetype name"
          exit 1
  fi

  if [ -n "$HOSTED_ZONE" -a -n "$SUBDOMAIN" ]
  then
    echo "Creating subdomain '$SUBDOMAIN' for load balancer"

    nlb_name=$(getNLBDNSName "$external_nlb")
    hosted_zone_name=$(getHostedZoneName "$HOSTED_ZONE")
    echo -e "\tHosted zone name: $hosted_zone_name"
    addSubdomain "$nlb_name" "$HOSTED_ZONE" "$hosted_zone_name" "$SUBDOMAIN"
  fi
}

removeLoadBalancers() {
  echo "Deleting load balancers"
  source $DELETE_SCRIPT_PATH
}

case $COMMAND in
  create)
    echo "Creating Load Balancer"
    createLoadBalancers
    ;;
  remove)
    echo "Removing Load Balancer"
    removeLoadBalancers
    ;;
  *)
    printUsage
    ;;
esac