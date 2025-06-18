#!/usr/bin/env bash

file=$(mktemp -t res_XXX)
unset res_names
declare -a res_names

openstack resource provider list -c name -c uuid -f value > ${file}
while read UUID name; do 
	echo -n "\"${name}\"," && openstack resource provider inventory list ${UUID} --format csv
	res_names+=("${name}")
done < ${file} > resource_usage.out.csv


for i in $(seq 0 $((${#res_names[@]} - 1 ))); do 
	#echo "$i : ${res_names[$i]}, next : ${res_names[$i+1]}"; 
done
