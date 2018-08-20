#!/bin/ash

# 禁止信号弱的客户端联网，防止发生全局性的拥塞
# 使用macfilter和parentalctl的firewall规则进行限制

maclist=`iwinfo wl1 assoclist | sed -n '8,$p' | cut -f1 -d " "`  #wl1为2.4G的信号
len=`iwinfo wl1 assoclist | sed -n '8,$p'  | sed -n '$='`

rxlist=`iwinfo wl1 assoclist | sed -n '8,$p' | cut -f7 -d " "`
rxlistsum=`iwinfo wl1 assoclist | sed -n '8,$p' | cut -f7 -d " " | sed -n '$='`

rxref="-80" #小于改值的客户端会被禁止连网

for i in `seq $len`;
do
	let "ii =  $i - 1"
	let "macpos =  $ii  * 17 + $ii"
	mac=${maclist:$macpos:17}
	
	let "rxpos =  $ii  * 3+ $ii"
	rx=${rxlist:$rxpos:3}

	unset macth

        if [[ $rx -le $rxref ]]; then
		echo $mac $rx
		
		let "j = 0"
		while  [ "`uci get macfilter.@mac[${j}]`" ==  "mac" ];
		do
			if  [ "`uci get macfilter.@mac[${j}].mac |  tr '[a-z]' '[A-Z]'`" ==  "$mac" ]; then
				let "macth = $j"
			fi
			let "j = $j + 1"
		done

		if [ -z $macth ];then
			let "macth = $j"
			uci add macfilter mac
		fi

		if  [ "`uci get macfilter.@mac[${macth}].wan`" ==  "no" ]; then
			continue
		fi

		uci set macfilter.@mac[$macth].mac=$mac
		uci set macfilter.@mac[$macth].lan=no
		uci set macfilter.@mac[$macth].wan=no
		uci set macfilter.@mac[$macth].admin=yes
		uci set macfilter.@mac[$macth].pridisk=no

		if  [ "`uci get parentalctl.$(echo $mac | tr -d ':')`" ==  "summary" ]; then
			uci set parentalctl.$(echo $mac | tr -d ':').mode=limited
		else
			uci set parentalctl.$(echo $mac | tr -d ':')=summary
			uci set parentalctl.$(echo $mac | tr -d ':').mac=$mac
			uci set parentalctl.$(echo $mac | tr -d ':').disabled=0
			uci set parentalctl.$(echo $mac | tr -d ':').mark=1
			uci set parentalctl.$(echo $mac | tr -d ':').mode=limited
		fi
		
		uci commit
	else
		echo $mac $rx
		
		let "j = 0"
		while  [ "`uci get macfilter.@mac[${j}]`" ==  "mac" ];
		do
			if  [ "`uci get macfilter.@mac[${j}].mac |  tr '[a-z]' '[A-Z]'`" ==  "$mac" ]; then
				let "macth = $j"
			fi
			let "j = $j + 1"
		done

		if [ -z "$macth" ];then
			continue
		fi

		if  [ "`uci get macfilter.@mac[${macth}].wan`" ==  "yes" ]; then
			continue
		fi

		uci set macfilter.@mac[$macth].lan=yes
		uci set macfilter.@mac[$macth].wan=yes
		
		uci set parentalctl.$(echo $mac | tr -d ':').mode=none

		uci commit
	fi
	
	# 重载规则
	/lib/firewall.sysapi.loader parentalctl
	/lib/firewall.sysapi.loader macfilter

done
