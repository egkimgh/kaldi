#!/bin/bash

read line
while read line
do
	IFS="/" read -ra new_dir <<< "${line}"
	src="../../isolated/$line"
	dst="$line"
	
	cmd="mkdir -p -v ${new_dir[-2]}"
	echo $cmd
	$cmd
	cmd="ln -s -f $src $dst"
	echo $cmd
	$cmd

done < "${1:-/dev/stdin}"
