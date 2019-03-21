#!/usr/bin/env bash
host=$1
port=$2

respuesta=$(curl -s http://$host:$port)

if [ ! -z "$respuesta" ]; then
  if [ "$respuesta" == "Aplicación de laboratorio v1" ]; then
    echo "STATUS: Success"
    echo "Value : $respuesta"
    exit 0
  else
    echo "STATUS: Failed"
    echo "Value : $respuesta"
    exit 1
  fi
else
  echo "No recibi ninguna respuesta"
  exit 1
fi
