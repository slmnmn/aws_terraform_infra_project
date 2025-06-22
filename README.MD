hola

Lambda_Function.py era para hacer una prueba subiendo el propio archivo desde Lambda.tf, pero no hace falta. Se hara un workflow aparte para poder subirlo cuando este listo si es que se necesita cambiar.



zip -j deploy.zip ./lambda/*
aws lambda update-function-code --function-name="name" --zip-file=fileb://deploy.zip

ESO NO ES NECESARIO. DADO QUE YA HA QUEDADO TODO PARA UN DESPLIEGUE RAPIDO SOLO EJECUTANDOLO.