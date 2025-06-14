import time
import json
import re
import random
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ✅ Ruta corregida y confirmada del chromedriver
service = Service(r"C:\Users\PC\chromedriver\chromedriver.exe\chromedriver.exe")
options = webdriver.ChromeOptions()
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument("--start-maximized")
driver = webdriver.Chrome(service=service, options=options)

# Limpieza del texto extraído
def limpiar_texto(texto):
    texto = re.sub(r'\s+', ' ', texto)
    texto = re.sub(r'\s*([:;,.])\s*', r'\1 ', texto)
    texto = re.sub(r'(?<=[a-z])\. (?=[A-Z])', '.\n\n', texto)
    texto = re.sub(r"Evaluation Only\. Created with Aspose\.Pdf\. Copyright 2002-2017 Aspose Pty Ltd\.", "", texto)
    return texto.strip()

# Extraer nombre del fallo (entre comillas)
def extraer_nombre_fallo(texto):
    nombre = re.search(r'“(.*?)”', texto)
    if nombre:
        return nombre.group(1).strip()
    return "Nombre de fallo no encontrado"

# Scroll hasta el final detectando el borde inferior real (versión optimizada)
def scroll_hasta_el_final_y_cerrar_rapido():
    viewer = driver.find_element(By.ID, "viewerContainer")
    ultimo_scroll = -1
    intentos_sin_cambio = 0

    for _ in range(50):  # limite razonable
        driver.execute_script("arguments[0].scrollBy(0, 800);", viewer)
        time.sleep(0.2)

        scroll_top = driver.execute_script("return arguments[0].scrollTop;", viewer)
        scroll_height = driver.execute_script("return arguments[0].scrollHeight;", viewer)
        client_height = driver.execute_script("return arguments[0].clientHeight;", viewer)

        if scroll_top + client_height >= scroll_height - 10:
            print("✅ Scroll llegó al final real")
            return

        if scroll_top == ultimo_scroll:
            intentos_sin_cambio += 1
        else:
            intentos_sin_cambio = 0

        if intentos_sin_cambio >= 3:
            print("✅ Scroll detenido (sin cambios), fin asumido")
            return

        ultimo_scroll = scroll_top

try:
    driver.get("https://apps1.juschubut.gov.ar/Eureka/")
    WebDriverWait(driver, 8).until(EC.element_to_be_clickable((By.ID, "btnAccesoAnonimo"))).click()
    print("✅ Acceso anónimo ingresado")

    driver.get("https://apps1.juschubut.gov.ar/Eureka/Sentencias/Buscar/Fallos/")
    WebDriverWait(driver, 8).until(EC.presence_of_element_located((By.ID, "txtTexto"))).send_keys("daños y perjuicios")
    driver.find_element(By.ID, "btnBuscar").click()
    print("✅ Búsqueda enviada")

    try:
        WebDriverWait(driver, 3).until(EC.visibility_of_element_located((By.ID, "modalReferencial")))
        driver.find_element(By.CSS_SELECTOR, "#modalReferencial button.close").click()
        print("✅ Cartel cerrado")
    except:
        print("⚠ No apareció cartel de aviso")

    filas = driver.find_elements(By.XPATH, "//tbody[@id='stjGrid-body']/tr")[:2]
    print(f"✅ Se detectaron {len(filas)} fallos")

    fallos = []

    for i, fila in enumerate(filas):
        try:
            fila.find_element(By.XPATH, ".//button[@title='Abrir sentencia']").click()
            print(f"✅ Abriendo fallo {i+1}")

            WebDriverWait(driver, 8).until(EC.frame_to_be_available_and_switch_to_it((By.ID, "iframeDetalle")))
            WebDriverWait(driver, 8).until(EC.presence_of_element_located((By.ID, "viewerContainer")))

            # Espera entre 3 y 4 segundos ANTES del scroll
            time.sleep(random.uniform(3, 4))

            scroll_hasta_el_final_y_cerrar_rapido()

            bloques = driver.find_elements(By.CSS_SELECTOR, ".textLayer div")
            texto_completo = " ".join([b.text.strip() for b in bloques if b.text.strip()])
            texto_limpio = limpiar_texto(texto_completo)

            nombre_fallo = extraer_nombre_fallo(texto_limpio)

            driver.switch_to.default_content()
            cabecera = driver.find_element(By.CLASS_NAME, "modal-header").text
            organismo = cabecera.split("\n")[0].strip() if "\n" in cabecera else cabecera.strip()

            fallo = {
                "nombre_fallo": nombre_fallo,
                "organismo": organismo,
                "content": texto_limpio
            }
            fallos.append(fallo)

            driver.find_element(By.CSS_SELECTOR, "#divDetalleModal button.close").click()
            print(f"✅ Fallo {i+1} procesado")
            time.sleep(1)

        except Exception as e:
            print(f"⚠ Error en fallo {i+1}: {e}")
            driver.switch_to.default_content()

    if fallos:
        with open("fallos.json", "w", encoding="utf-8") as f:
            json.dump(fallos, f, indent=2, ensure_ascii=False)
        print("✅ Se guardaron correctamente en fallos.json")
    else:
        print("⚠ No se guardaron fallos")

finally:
    driver.quit()
