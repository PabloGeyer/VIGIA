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
