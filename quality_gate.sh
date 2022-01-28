#!/bin/bash

app="$1"
arquivoGet="resultadoGET_$app.json"
arquivoPost="resultadoPOST_$app.json"
comAspas='"'
semAspas=''
urlSonarApi="sonar-domain/api"
getQualityGateShow="$urlSonarApi/qualitygates/show"
getMeasures="$urlSonarApi/measures/component"
postQualityGateUpdateContition="$urlSonarApi/qualitygates/update_condition"
authBasic="sonar-auth-token"

if [ "$app" == '' ]
then
    echo "Para o script funcionar é necessário informar o nome do projeto por parãmetro, ex.: ./arquivo.sh 'nome'"
    exit 1
fi

echo "GET $getQualityGateShow?name=$app"

curl -H "Authorization: Basic $authBasic" -X GET "$getQualityGateShow?name=$app" | jq "." > $arquivoGet

echo "leitura dos dados e armazenamento em variável"

idGate=$(jq '."id"' $arquivoGet)
idGate=${idGate//$comAspas/$semAspas}

qgMetric=$(jq '.conditions[0].metric' $arquivoGet)
qgMetric=${qgMetric//$comAspas/$semAspas}

qgId=$(jq '.conditions[0].id' $arquivoGet)
qgId=${qgId//$comAspas/$semAspas}

qgOp=$(jq '.conditions[0].op' $arquivoGet)
qgOp=${qgOp//$comAspas/$semAspas}

bugs=$(curl -H "Authorization: Basic $authBasic" -X GET "$getMeasures?component=$app&metricKeys=bugs" | jq ".component.measures[0].value")
bugs=${bugs//$comAspas/$semaspas}

echo code_smells=$(curl -H "Authorization: Basic $authBasic" -X GET "$getMeasures?component=$app&metricKeys=code_smells" | jq ".component.measures[0].value")
code_smells=${codesmells//$comAspas/$semaspas}

echo "Valores identificados:"

if [ "$qgMetric" == "bugs" ] && [ $bugs -gt 0 ]
then
    menosUm=1
    resultadoMenosUm=$(echo "$bugs - $menosUm"|bc)
    echo "******* Atualização do Quality Gate *******
          ******* Agora, a régua terá tolerância de $resultadoMenosUm bug(s) no projeto *******
          ******* Tolerância anterior: $bugs bug(s)*******"

    echo "POST $postQualityGateUpdateContition"
    curl -H "Authorization: Basic $authBasic" -X POST "$postQualityGateUpdateContition?gateId=$idGate&id=$qgId&metric=$qgMetric&op=$qgOp&error=$resultadoMenosUm" > $arquivoPost
else
    echo "Não foram identificados bugs para este projeto!"
fi

if [ "$qgMetric" == "code_smells" ] && [ $code_smells -gt 0 ]
then
    menosUm=1
    resultadoMenosUm=$(echo "$code_smells - $menosUm"|bc)
    echo "******* Atualização do Quality Gate *******
          ******* Agora, a régua terá tolerância de $resultadoMenosUm code smell(s) no projeto*******
          ******* Tolerância anterior: $code_smells code smell(s)*******"

    echo "POST $postQualityGateUpdateContition"
    curl -H "Authorization: Basic $authBasic" -X POST "$postQualityGateUpdateContition?gateId=$idGate&id=$qgId&metric=$qgMetric&op=$qgOp&error=$resultadoMenosUm" > $arquivoPost
else
    echo "Não foram identificados code smells para este projeto!"
fi


echo "finalizado"
