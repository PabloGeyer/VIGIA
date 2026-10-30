# Vigía

> Vigilante open source para tus automatizaciones: te avisa cuando algo falla o deja de correr.

## ¿De qué se trata?

Hoy cualquier empresa o dev tiene automatizaciones desparramadas por todos lados: un backup que corre de madrugada, flujos de n8n, scripts con cron, GitHub Actions, cosas en Zapier... y cuando alguna se rompe o deja de correr, nadie se entera hasta que es tarde.

Vigía resuelve eso de forma súper simple: cada automatización tiene una URL única, y al terminar de correr le "avisa" al vigilante haciendo un request a esa URL (tipo "llegué bien"). Si el aviso no llega en el horario esperado, o si la automatización avisa que falló, el sistema manda una alerta por Telegram, mail o WhatsApp. También tiene un panel web donde ves todas tus automatizaciones con su estado (OK, falló, no corrió) y el detalle del error.

```bash
./hacer_backup.sh && curl https://vigia.tuempresa.com/ping/backup-nocturno
```

## Lo que va a tener

- Funciona con cualquier cosa que pueda llamar a una URL (scripts, n8n, crons, GitHub Actions, Zapier).
- Fácil de adoptar: agregás una línea al final de la automatización y listo.
- Open source y autohosteable con un solo comando de Docker.
- Alertas por Telegram y mail primero, WhatsApp después.
- Más adelante, integraciones directas con n8n y GitHub para leer las ejecuciones sin que el usuario tenga que tocar nada.

## ¿En qué se diferencia?

Existe algo parecido (Healthchecks.io), pero Vigía está pensado para automatizaciones en general y no solo para crons: integraciones nativas con n8n, alertas por WhatsApp y Telegram, ver el error concreto y una instalación muy simple.

## Arquitectura

1. **Servidor** que recibe los avisos y los guarda en una base de datos.
2. **Revisor** que cada minuto chequea qué automatizaciones están atrasadas.
3. **Sistema de alertas** (Telegram, mail, WhatsApp).
4. **Panel web** con el estado de todo.

## Estado

🚧 En etapa inicial. Proyecto desarrollado por un estudiante de Ingeniería en Sistemas de Información, con buenas prácticas pero arrancando simple.

## Licencia

[MIT](LICENSE)
