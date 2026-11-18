# Vigía

> Vigilante open source para tus automatizaciones: te avisa cuando algo falla o deja de correr, y con IA te explica por qué y cómo arreglarlo.

## ¿De qué se trata?

Hoy cualquier empresa o dev tiene automatizaciones desparramadas por todos lados: un backup que corre de madrugada, flujos de n8n, scripts con cron, GitHub Actions, cosas en Zapier... y cuando alguna se rompe o deja de correr, nadie se entera hasta que es tarde.

Vigía resuelve eso de forma súper simple: cada automatización tiene una URL única, y al terminar de correr le "avisa" al vigilante haciendo un request a esa URL (tipo "llegué bien"). Si el aviso no llega en el horario esperado, o si la automatización avisa que falló, el sistema manda una alerta por Telegram, mail o WhatsApp. También tiene un panel web donde ves todas tus automatizaciones con su estado (OK, falló, no corrió) y el detalle del error.

```bash
./hacer_backup.sh && curl https://vigia.tuempresa.com/ping/backup-nocturno
```

## Diagnóstico con IA

Saber que algo falló es la mitad del problema; la otra mitad es entender por qué. Cuando una automatización falla, Vigía junta el contexto (el mensaje de error, los logs que mandó la automatización y, si es un flujo de n8n, la definición del workflow) y se lo pasa a un modelo de IA. La alerta no llega como un simple "falló", sino con un diagnóstico:

> 🔴 **Falló "Ventas → planilla" (n8n)**
>
> **Causa probable:** la API de Google Sheets respondió `401 Unauthorized`. El token de la credencial "Google - Ventas" venció.
>
> **Cómo arreglarlo:** en n8n, entrá a *Credentials → Google - Ventas* y volvé a conectar la cuenta. Después reejecutá la ejecución fallida desde el historial.

### Cómo funciona

1. La automatización avisa que falló y manda el error: `curl -d "$ERROR" https://vigia.tuempresa.com/ping/ventas/fail`
2. Vigía arma el contexto: error, logs, historial reciente (¿falló antes?, ¿cuándo anduvo bien por última vez?) y la definición del flujo si la tiene.
3. **Antes de mandarlo al modelo, borra los secretos**: tokens, contraseñas, API keys y emails se reemplazan automáticamente.
4. El modelo devuelve causa probable, cómo arreglarlo y qué tan seguro está.
5. El diagnóstico se adjunta a la alerta y queda guardado en el panel.

### Tu modelo, tus datos

- **Traés tu propia API key**: Anthropic (Claude), OpenAI o cualquier proveedor compatible.
- **O 100 % local con [Ollama](https://ollama.com)**: nada sale de tu servidor.
- **Es opcional**: sin IA configurada, Vigía funciona igual como monitor.

## ¿Cómo se conecta una automatización?

Las automatizaciones **no necesitan tener una URL**: la URL es de Vigía. Vigía no va a buscar a tus automatizaciones; son ellas las que le avisan cuando terminan, como alguien que manda "ya hice el backup ✅" a un grupo.

```
Tu automatización                         Vigía
(script, n8n, GitHub...)                  (tiene la URL)

  hace su trabajo y termina
  ── "terminé bien" ──────────────►  /ping/a7f3k9x2        ✅ anotado
  (otro día falla)
  ── "fallé: error 401" ──────────►  /ping/a7f3k9x2/fail   🔴 alerta + diagnóstico IA
  (otro día ni arranca)
        (silencio)                   pasó la hora y no llegó nada  🔴 alerta
```

1. **Registrás la automatización en Vigía**: nombre, cada cuánto debería correr y cuánto margen le das.
2. **Vigía le asigna un código único** y te da su URL, por ejemplo `https://vigia.tudominio.com/ping/a7f3k9x2`. El código es largo y aleatorio, así que funciona como contraseña: nadie más puede mandarte avisos falsos.
3. **Agregás una línea al final de la automatización** que llama a esa URL. No hay que cambiar nada más.

### Ejemplos

**Script con cron (Linux)**: `&&` avisa si anduvo, `||` avisa si falló.

```bash
0 3 * * * /home/usuario/backup.sh && curl -fsS https://vigia.tudominio.com/ping/a7f3k9x2 \
  || curl -fsS -d "backup.sh falló" https://vigia.tudominio.com/ping/a7f3k9x2/fail
```

**Python**: mandar el traceback completo le da material a la IA para diagnosticar.

```python
import requests, traceback

VIGIA = "https://vigia.tudominio.com/ping/a7f3k9x2"

try:
    procesar_ventas()          # lo que ya hacía tu script
    requests.get(VIGIA, timeout=10)
except Exception:
    requests.post(f"{VIGIA}/fail", data=traceback.format_exc(), timeout=10)
    raise
```

**n8n**
- *Si anduvo:* al final del flujo, un nodo **HTTP Request** (GET) a la URL de Vigía.
- *Si falló:* un flujo aparte que empieza con **Error Trigger** y termina en un **HTTP Request** (POST) a `/fail` con el mensaje de error. En la configuración del flujo original lo elegís como *Error workflow*; uno solo sirve para todos tus flujos.

**GitHub Actions**: la URL se guarda como secreto del repo (`VIGIA_URL`).

```yaml
      - name: Avisar a Vigía
        if: always()
        run: |
          if [ "${{ job.status }}" = "success" ]; then
            curl -fsS ${{ secrets.VIGIA_URL }}
          else
            curl -fsS -d "Falló el job ${{ github.job }}" ${{ secrets.VIGIA_URL }}/fail
          fi
```

**Zapier o Make**: un último paso **Webhooks → GET** a la URL de Vigía. Si el zap falla, el aviso no llega y Vigía alerta que no corrió.

**Windows (Programador de tareas)**: al final del script de PowerShell:

```powershell
Invoke-RestMethod https://vigia.tudominio.com/ping/a7f3k9x2
```

> **Importante:** la automatización tiene que poder llegar a Vigía. Si corre en otro servidor, en n8n cloud o en GitHub, Vigía tiene que estar publicado en internet (desplegado con un dominio, o expuesto temporalmente con un túnel como `cloudflared` o ngrok para probar).

## Probarlo sin automatizaciones reales

A Vigía le da igual si el aviso viene de un backup real o de una prueba, así que se puede simular todo:

**A mano, con `curl`:**

```bash
curl http://localhost:8080/ping/prueba                                                   # "llegué bien"
curl -d "Error 401 Unauthorized: token expired" http://localhost:8080/ping/prueba/fail   # "fallé"
```

Para probar el caso "no corrió", no mandás nada: configurás la automatización como "cada 2 minutos" y esperás la alerta.

**Con el simulador**: [`ejemplos/simulador.sh`](ejemplos/simulador.sh) hace de tres automatizaciones falsas: una que siempre anda, otra que falla 1 de cada 3 veces con errores variados (ideal para probar el diagnóstico con IA) y otra que nunca avisa.

```bash
bash ejemplos/simulador.sh
```

**Automatizaciones "de juguete"**: n8n local con Docker (`docker run -p 5678:5678 n8nio/n8n`) con un flujo programado cada 5 minutos, un workflow de GitHub Actions con `schedule` en un repo de prueba, o un cron inofensivo en tu propia PC.

## Lo que va a tener

- Funciona con cualquier cosa que pueda llamar a una URL (scripts, n8n, crons, GitHub Actions, Zapier).
- Fácil de adoptar: agregás una línea al final de la automatización y listo.
- Open source y autohosteable con un solo comando de Docker.
- Alertas por Telegram y mail primero, WhatsApp después.
- Más adelante, integraciones directas con n8n y GitHub para leer las ejecuciones sin que el usuario tenga que tocar nada.

## ¿En qué se diferencia?

Existen monitores parecidos (Healthchecks.io, Cronitor), pero solo te dicen *que* algo falló. Vigía te dice **por qué y cómo arreglarlo**. Además está pensado para automatizaciones en general y no solo para crons: integraciones nativas con n8n, alertas por WhatsApp y Telegram y una instalación muy simple.

## Arquitectura

1. **Servidor** que recibe los avisos y los guarda en una base de datos.
2. **Revisor** que cada minuto chequea qué automatizaciones están atrasadas.
3. **Sistema de alertas** (Telegram, mail, WhatsApp).
4. **Panel web** con el estado de todo.
5. **Diagnosticador** que, cuando algo falla, limpia los secretos, consulta al modelo de IA y adjunta el diagnóstico a la alerta.

## Hoja de ruta

- [ ] **v0.1:** recibir avisos (`/ping/:id` y `/ping/:id/fail`), detectar atrasos, alertas por Telegram.
- [ ] **v0.2:** panel web y alertas por mail.
- [ ] **v0.3:** diagnóstico con IA (Claude, OpenAI, Ollama) con limpieza de secretos.
- [ ] **v0.4:** integración nativa con n8n (lee el workflow y las ejecuciones automáticamente).
- [ ] **v0.5:** sugerencia de arreglo aplicable (por ejemplo, el JSON del nodo corregido) y alertas por WhatsApp.

## Licencia

[MIT](LICENSE)
