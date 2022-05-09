#!/usr/bin/sh
JSON1=./card_sh.template
JSON2=./card_ab.template

cat ${1:?} | while read LINE
do
	gameName=$(echo $LINE | awk -F "|" '{print $3}')
	cName=$(echo $LINE | awk -F "|" '{print $2}')
	facName=$(echo $LINE | awk -F "|" '{print $8}')
	shipClass=$(echo $LINE | awk -F "|" '{print $5}')
	ability=$(echo $LINE | awk -F "|" '{print $12}')
	imgURI=$(echo $LINE | awk -F "|" '{print $13}')
	cType=$(echo $LINE | awk -F "|" '{print $4}')
	shipType=$(echo $LINE | awk -F "|" '{print $6}')
	tech=$(echo $LINE | awk -F "|" '{print $11}')
	cost=$(echo $LINE | awk -F "|" '{print $10}')
	rare=$(echo $LINE | awk -F "|" '{print $9}')
	
	newFile=/home/ec2-user/json/build/${cName}.json
	
	if [[ ${cName} =~ "SH" ]]; then
		cp $JSON1 ${newFile}
	else
		cp $JSON2 ${newFile}
	fi
	
	sed -i "s|@GAMENAME@|${gameName}|g" ${newFile}
	sed -i 's/@NAME@/'${cName}'/g' ${newFile}
	sed -i "s|@FACNAME@|${facName}|g" ${newFile}
	sed -i "s|@SHIPCLASS@|${shipClass}|g" ${newFile}
	sed -i 's/@IMGURI@/'${imgURI}'/g' ${newFile}
	sed -i 's/@CARDTYPE@/'${cType}'/g' ${newFile}
	sed -i "s|@SHIPTYPE@|${shipType}|g" ${newFile}
	sed -i 's/@TECH@/'${tech}'/g' ${newFile}
	sed -i 's/@COST@/'${cost}'/g' ${newFile}
	sed -i 's/@RARITY@/'${rare}'/g' ${newFile}
	
	sed -i "s|@ABILITY@|${ability}|g"	${newFile}

	# Clean up
	sed -i '/"description": ""/d' ${newFile}
	sed -i '/"description": " - "/d' ${newFile}

	
	#sed -i 's/./ /g' ${newFile}
done