#!/usr/bin/env bash

respuesta=$(curl -s http://localhost:32000)

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
