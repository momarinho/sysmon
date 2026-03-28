import asyncio
import json
import time

import psutil
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI()


def get_sys_metrics() -> dict:
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    temps = {}
    if hasattr(psutil, "sensors_temperatures"):
        temps_raw = psutil.sensors_temperatures()
        k10 = temps_raw.get("k10temp") or temps_raw.get("coretemp") or []
        if k10:
            temps = {
                "label": k10[0].label or "CPU",
                "current": k10[0].current,
            }

    uptime_seconds = int(time.time() - psutil.boot_time())
    hours, rem = divmod(uptime_seconds, 3600)
    minutes = rem // 60

    return {
        "cpu": psutil.cpu_percent(interval=None),
        "ram": mem.percent,
        "ram_used": round(mem.used / 1e9, 1),
        "ram_total": round(mem.total / 1e9, 1),
        "disk": disk.percent,
        "disk_used": round(disk.used / 1e9, 1),
        "disk_total": round(disk.total / 1e9, 1),
        "temp": temps,
        "uptime": f"{hours}h {minutes}min",
        "timestamp": time.time(),
    }


@app.websocket("/ws/metrics")
async def metrics_ws(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            metrics = get_sys_metrics()
            await websocket.send_text(json.dumps(metrics))
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        print("Client disconnected")
