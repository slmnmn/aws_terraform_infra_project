import boto3
import json
import uuid # Para generar IDs únicos
import os # Para obtener variables de entorno
from datetime import datetime, timezone, timedelta # Importar librerías de fecha y hora
import urllib.parse # Para codificar la clave del objeto para el enlace URL

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(evento, contexto):
    """
    Esta función Lambda es activada por un evento de S3.
    Crea un nuevo ítem en una tabla de DynamoDB que contiene el nombre del archivo,
    una marca de tiempo (timestamp) del procesamiento y un enlace directo al objeto de S3.
    """
    
    # --- 1. Obtener el nombre de la tabla de DynamoDB desde las variables de entorno ---
    # La variable de entorno se configura en la propia función Lambda en AWS.
    nombre_tabla_dynamodb = os.environ.get('DYNAMODB_TABLE_NAME')
    if not nombre_tabla_dynamodb:
        print("Error: La variable de entorno DYNAMODB_TABLE_NAME no está configurada.")
        return {
            'statusCode': 500,
            'body': json.dumps('Error de configuración del servidor: Falta el nombre de la tabla.')
        }
        
    tabla = dynamodb.Table(nombre_tabla_dynamodb)

    try:
        # --- 2. Extraer información del registro del evento de S3 ---
      
        for registro in evento['Records']:
            nombre_bucket = registro['s3']['bucket']['name']
            clave_objeto = registro['s3']['object']['key'] # Este es el nombre del archivo.
            region = registro['awsRegion']
            
            print(f"Nuevo archivo detectado: '{clave_objeto}' en el bucket '{nombre_bucket}'")

            # --- 3. Construir la URL del objeto S3 ---
            clave_codificada = urllib.parse.quote_plus(clave_objeto)
            enlace_s3 = f"https://{nombre_bucket}.s3.{region}.amazonaws.com/{clave_codificada}"
        
        
            id_item = str(uuid.uuid4())
            zona_horaria_utc_menos_5 = timezone(timedelta(hours=-5))
            
            # Obtener la hora actual en la zona horaria especificada y formatearla en estándar ISO.
            timestamp_texto = datetime.now(zona_horaria_utc_menos_5).isoformat()

            item_para_guardar = {
                'id': id_item,          # La clave primaria de la tabla debe llamarse 'id'.
                'placa': "RKW326",
                'Objeto': clave_objeto,  # El nombre del archivo se guarda en el atributo 'placa'.
                'hora': timestamp_texto,# La fecha y hora se guardan en el atributo 'hora'.
                'linkplaca': enlace_s3  # El enlace directo al archivo S3.
            }

            # --- 5. Escribir el ítem en DynamoDB ---
            print(f"Escribiendo ítem en DynamoDB: {json.dumps(item_para_guardar)}")
            
            tabla.put_item(
                Item=item_para_guardar
            )

            print("Ítem escrito exitosamente en DynamoDB.")

        # --- 6. Devolver una respuesta de éxito ---
        return {
            'statusCode': 200,
            'body': json.dumps('Evento de S3 procesado y datos guardados en DynamoDB exitosamente.')
        }

    except KeyError as e:
        # Manejar casos donde la estructura del evento no es la esperada.
        print(f"Error: Falta la clave en el registro del evento - {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps(f'Registro de evento S3 malformado: {str(e)}')
        }
    except Exception as e:
        # Captura genérica para otros errores potenciales (ej. problemas de permisos de AWS).
        print(f"Ocurrió un error inesperado: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error interno del servidor: {str(e)}')
        }