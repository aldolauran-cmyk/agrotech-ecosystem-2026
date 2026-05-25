import random
import time
import requests

BASE_URL = "http://127.0.0.1:8000/api/v1"


def get_valid_token():
    print("Enviando credenciales de desarrollo ('admin' / 'admin123')...")
    try:
        response = requests.post(
            f"{BASE_URL}/token",
            data={
                "username": "admin",
                "password": "admin123"
            },
            timeout=5
        )
        if response.status_code == 200:
            print("--> ¡ÉXITO! Conexión establecida con el backend.")
            return response.json().get("access_token")
        else:
            print(f"Error en login: Código {response.status_code}")
            print(f"Detalle del servidor: {response.json()}")
            return None
    except requests.exceptions.Timeout:
        print("Error: El servidor tardó demasiado en responder (Timeout).")
        return None
    except Exception as e:
        print(f"Error de conexión con el backend: {e}")
        return None


def garantizar_parcela_existente(headers):
    """Verifica si existen parcelas, de lo contrario crea la Parcela ID 1"""
    print("Verificando disponibilidad de parcelas en el sistema...")
    try:
        response = requests.get(f"{BASE_URL}/parcels", headers=headers, timeout=5)
        # Si la lista está vacía, creamos la primera parcela de prueba
        if response.status_code == 200 and len(response.json()) == 0:
            print("No se encontraron parcelas. Creando 'Parcela Demostración 1'...")
            nueva_parcela = {
                "name": "Parcela Demostración 1",
                "location": "Sector Norte - Lote A",
                "soil_type": "Franco-Arcilloso"
            }
            create_resp = requests.post(
                f"{BASE_URL}/parcels", 
                json=nueva_parcela, 
                headers=headers, 
                timeout=5
            )
            if create_resp.status_code == 201:
                print(f"--> ¡Parcela creada con éxito! ID: {create_resp.json().get('id')}")
            else:
                print(f"Alerta al crear parcela: {create_resp.text}")
        else:
            print("--> Conexión de parcelas verificada. Listo para transmitir.")
    except Exception as e:
        print(f"Advertencia al verificar parcelas: {e}. Se intentará el envío de igual modo.")


# 🚨 PROTECCIÓN DEFINITIVA: Flujo principal de ejecución del simulador
if __name__ == "__main__":
    token = get_valid_token()

    if not token:
        print("\n[!] No se pudo obtener el token. Asegúrate de que el backend esté corriendo en la otra terminal.")
        exit()

    headers = {"Authorization": f"Bearer {token}"}
    
    # Aseguramos que exista la relación en la BD antes de mandar datos huérfanos
    garantizar_parcela_existente(headers)
    
    print("\n¡Autenticación y entorno completados! Enviando telemetría cada 5 segundos...\n")

    while True:
        data = {
            "humidity": random.randint(20, 80),
            "temperature": random.randint(15, 35),
            "ph": round(random.uniform(5.5, 7.5), 2),
            "parcel_id": 1  # Ahora garantizamos de forma segura que el ID 1 exista
        }
        try:
            response = requests.post(
                f"{BASE_URL}/telemetry", 
                json=data, 
                headers=headers, 
                timeout=5
            )
            if response.status_code == 201 or response.status_code == 200:
                print(f"[IoT Send] exitoso: {response.json()}")
            else:
                print(f" [IoT Error] Código {response.status_code}: {response.text}")
        except requests.exceptions.Timeout:
            print("Error: El envío de telemetría falló por límite de tiempo (Timeout).")
        except Exception as e:
            print(f"Error al enviar telemetría: {e}")
            
        time.sleep(5)