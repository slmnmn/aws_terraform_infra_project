# Terraform despliegue

## NOTA: TENGA EN CUENTA CAMBIAR LAS VARIABLES EN tf.vars A SU GUSTO 

**Este despliegue consiste en la creaciòn de diferentes recursos de AWS tales como lo son s3, lambda, dynamoDB y una apigateway para recibir PUT request provenientes de una website estatica de un S3**

S3 tiene un event trigger a una lambda que se encarga de parsear el evento para obtener el archivo subido y registrarlo en un dynamoDB con su hora, contenido y el lugar que se encuentra.

Cabe recalca que esta es una arquitectura como ejemplo que puede servir como base para poderla escalar a procesamiento de imagenes. Para esto, se puede refactorizar el codigo encontrado en el siguiente [repositorio](https://github.com/slmnmn/Yolov8_plus_PaddleOCR_plate_recognition)

Ademas de esto, el terraform state para que se pueda guardar de alguna manera en algun lugar, esta localizado en un bucket S3 creado con antelaciòn

## Retos encontrados

Si bien, el procesamiento de imagenes no es una muy dificl de implementar con un lambda contenedor, las librerias y dependencias utilizadas se ven bastante dificiles de ponerlas sin que tengan conflicto en el contenedor sin pesar mucho. El problema real no es el espacio maximo de las 10GB (para eso usamos alpine linux y limpiamos al final), si no por algunos inconvenientes con los compiladores necesarios a la hora de hacer el docker.

Es por esto mismo que para la demostraciòn se utiliza como ejemplo una lambda .zip para poder demostrar lo que que se puede lograr.

## Pipelines

El pipeline de despliegue consiste en lo siguiente:

* El usuario pushea a main (cambiar esto en la GithubAction)
* Se ejecuta un **terraform apply** teniendo en cuenta que ya estan configuradas las credenciales de la cuenta 
* La infraestructura queda completamente levantada
* Los outputs nos daran el nombre del bucket necesario y el invoke URL para poder usarlo en nuestra [static website](https://github.com/slmnmn/staticwebsite-to-upload-to-s3).
* El usuario final tiene control completo sobre la static website y puede cambiar el codigo de la lambda desde este repositorio para poder cambiar su codigo (cada vez se hace el **init**, se crea un .zip con el codigo antes de enviar con el **apply**)

El pipeline de destroy ejecuta el destroy de toda la infraestructura de manera manual.

* Cabe recalcar, que esto se puede hacer de manera sencilla y rapida dado que los buckets tienen lo siguiente
```
  force_destroy = true 
```
* Se recomienda hacer una copia de los buckets antes que usar el terraform destroy action O borrar este parametro del codigo.

[![Apply Infrastructure](https://github.com/slmnmn/aws_terraform_infra_project/actions/workflows/terraform_apply_infra_lambda.yml/badge.svg)](https://github.com/slmnmn/aws_terraform_infra_project/actions/workflows/terraform_apply_infra_lambda.yml)

[![Destroy Infrastructure](https://github.com/slmnmn/aws_terraform_infra_project/actions/workflows/terraform_destroy_infra_lambda.yml/badge.svg)](https://github.com/slmnmn/aws_terraform_infra_project/actions/workflows/terraform_destroy_infra_lambda.yml)