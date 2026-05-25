import requests

BASE_URL = "http://127.0.0.1:8000/api/v1"

def create_admin():
    print("Intentando registrar al usuario administrador...")
    try:
        # Intentamos crear el usuario administrador directamente en el endpoint de registros
        response = requests.post(
            f"{BASE_URL}/users/",
            json={
                "email": "admin@agrotech.com",
                "password": "adminpassword",
                "full_name": "Administrador Agrotech",
                "role": "admin"
            }
        )
        if response.status_code == 200 or response.status_code == 201:
            print("¡Usuario administrador creado con éxito!")
        elif response.status_code == 400:
            print("El usuario ya existe o hubo un problema con los datos (400).")
            print(response.json())
        else:
            print(f"No se pudo crear. Servidor respondió con código: {response.status_code}")
            print(response.json())
    except Exception as e:
        print(f"Error de conexión: {e}")

if __name__ == "__main__":
    create_admin()