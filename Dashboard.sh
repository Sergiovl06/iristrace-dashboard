#!/bin/bash

FILE_APIS="apis"
FILE_NIFIS="nifis"
OUTPUT_FILE="dashboard.html"
CONCURRENCY_LIMIT=20

if [[ ! -f "$FILE_APIS" ]] || [[ ! -f "$FILE_NIFIS" ]]; then
    echo "Error: Faltan los archivos '$FILE_APIS' o '$FILE_NIFIS'."
    exit 1
fi

echo "Iniciando monitorizacion de servicios de Iristrace..."

STACKS=$(cat "$FILE_APIS" "$FILE_NIFIS" 2>/dev/null | grep -oE 'STACK: "[^"]+"' | sed 's/STACK: "//;s/"//' | sort -u)
TOTAL_STACKS=$(echo "$STACKS" | wc -w)
FECHA_ACTUAL=$(date "+%d/%m/%Y %H:%M:%S")

echo "Se han encontrado $TOTAL_STACKS clientes. Analizando su estado..."

cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Status Dashboard</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --bg:         #07101f;
            --surface:    #0d1b2e;
            --surface2:   #0a1525;
            --surface3:   #112035;
            --border:     #1a2f48;
            --border2:    #1e3652;
            --accent:     #f97316;
            --accent-dim: rgba(249,115,22,0.15);
            --accent-bd:  rgba(249,115,22,0.35);
            --green:      #10b981;
            --green-bg:   rgba(16,185,129,0.08);
            --green-bd:   rgba(16,185,129,0.25);
            --red:        #ef4444;
            --red-bg:     rgba(239,68,68,0.08);
            --red-bd:     rgba(239,68,68,0.25);
            --blue:       #3b82f6;
            --blue-bg:    rgba(59,130,246,0.08);
            --blue-bd:    rgba(59,130,246,0.25);
            --text:       #e2e8f0;
            --text-sub:   #94a3b8;
            --text-muted: #4a647f;
            --radius:     10px;
            --hdr-shadow: 0 8px 32px rgba(0,0,0,0.45);
            --tbl-shadow: 0 4px 24px rgba(0,0,0,0.35);
            --row-hover:  rgba(255,255,255,0.018);
            --row-border: rgba(26,47,72,0.5);
        }
        [data-theme="light"] {
            --bg:         #eef2f8;
            --surface:    #ffffff;
            --surface2:   #f4f7fb;
            --surface3:   #e6edf6;
            --border:     #d4dde9;
            --border2:    #c2cfdf;
            --accent-dim: rgba(249,115,22,0.10);
            --accent-bd:  rgba(249,115,22,0.30);
            --green-bg:   rgba(16,185,129,0.07);
            --green-bd:   rgba(16,185,129,0.28);
            --red-bg:     rgba(239,68,68,0.07);
            --red-bd:     rgba(239,68,68,0.28);
            --blue-bg:    rgba(59,130,246,0.07);
            --blue-bd:    rgba(59,130,246,0.28);
            --text:       #0f172a;
            --text-sub:   #334155;
            --text-muted: #64748b;
            --hdr-shadow: 0 4px 18px rgba(0,0,0,0.10);
            --tbl-shadow: 0 2px 12px rgba(0,0,0,0.08);
            --row-hover:  rgba(0,0,0,0.025);
            --row-border: rgba(180,200,224,0.7);
        }
        body {
            font-family: 'DM Sans', sans-serif;
            background-color: var(--bg);
            color: var(--text);
            min-height: 100vh;
            overflow-x: hidden;
            transition: background-color 0.35s ease, color 0.2s ease;
        }
        body::before {
            content: '';
            position: fixed;
            inset: 0;
            background-image: radial-gradient(circle, rgba(249,115,22,0.06) 1px, transparent 1px);
            background-size: 30px 30px;
            pointer-events: none;
            z-index: 0;
        }
        body::after {
            content: '';
            position: fixed;
            top: -120px;
            left: 50%;
            transform: translateX(-50%);
            width: 600px;
            height: 240px;
            background: radial-gradient(ellipse, rgba(249,115,22,0.12) 0%, transparent 70%);
            pointer-events: none;
            z-index: 0;
        }
        .page-wrap {
            position: relative;
            z-index: 1;
            max-width: 1440px;
            margin: 0 auto;
            padding: 20px 24px 48px;
        }
        
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            padding: 18px 24px;
            background: linear-gradient(135deg, var(--surface) 0%, var(--surface2) 100%);
            border: 1px solid var(--border);
            border-top: 2px solid var(--accent);
            border-radius: var(--radius);
            margin-bottom: 16px;
            box-shadow: var(--hdr-shadow), 0 1px 0 rgba(255,255,255,0.03) inset;
            animation: slideDown 0.45s cubic-bezier(.16,1,.3,1);
        }
        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-14px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        .header-left {
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .logo-wrap {
            width: 44px;
            height: 44px;
            border-radius: 9px;
            overflow: hidden;
            flex-shrink: 0;
            background: #000;
            border: 1px solid var(--border2);
            box-shadow: 0 0 0 1px rgba(249,115,22,0.12);
        }
        .logo-wrap img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }
        .header-title h1 {
            font-family: 'Syne', sans-serif;
            font-size: 18px;
            font-weight: 700;
            color: var(--text);
            letter-spacing: -0.02em;
            line-height: 1.2;
        }
        .header-title h1 em {
            font-style: normal;
            color: var(--accent);
        }
        .header-meta {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 11.5px;
            color: var(--text-muted);
            font-family: 'JetBrains Mono', monospace;
            margin-top: 5px;
        }
        .live-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--green);
            box-shadow: 0 0 6px var(--green);
            flex-shrink: 0;
            animation: liveBlink 2.5s ease-in-out infinite;
        }
        @keyframes liveBlink {
            0%, 100% { opacity: 1;   box-shadow: 0 0 6px var(--green); }
            50%       { opacity: 0.4; box-shadow: 0 0 2px var(--green); }
        }
        .header-right {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .badge-total {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 8px 18px;
            background: var(--accent-dim);
            border: 1px solid var(--accent-bd);
            border-radius: 8px;
            text-align: center;
        }
        .badge-total-num {
            font-family: 'Syne', sans-serif;
            font-size: 22px;
            font-weight: 700;
            color: var(--accent);
            line-height: 1;
        }
        .badge-total-lbl {
            font-size: 10px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.07em;
            color: var(--text-muted);
            margin-top: 3px;
        }
        .refresh-btn {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 9px 15px;
            background: var(--surface3);
            border: 1px solid var(--border2);
            border-radius: 8px;
            color: var(--text-sub);
            font-family: 'DM Sans', sans-serif;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.18s ease;
        }
        .refresh-btn:hover {
            background: var(--accent-dim);
            border-color: var(--accent-bd);
            color: var(--accent);
        }
        .refresh-btn:hover .refresh-icon { animation: spin 0.5s linear; }
        .refresh-icon {
            width: 13px;
            height: 13px;
            fill: currentColor;
            flex-shrink: 0;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        
        .stats-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
            margin-bottom: 14px;
            animation: fadeUp 0.45s cubic-bezier(.16,1,.3,1) 0.08s both;
        }
        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(10px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        .stat-card {
            position: relative;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 16px 20px;
            display: flex;
            align-items: center;
            gap: 14px;
            overflow: hidden;
            transition: border-color 0.2s, box-shadow 0.2s;
        }
        .stat-card::before {
            content: '';
            position: absolute;
            inset: 0;
            opacity: 0;
            transition: opacity 0.2s;
        }
        .stat-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,0.3); }
        .stat-card.c-blue:hover  { border-color: rgba(59,130,246,0.4); }
        .stat-card.c-green:hover { border-color: rgba(16,185,129,0.4); }
        .stat-card.c-orange:hover{ border-color: rgba(249,115,22,0.4); }
        .stat-card.c-red:hover   { border-color: rgba(239,68,68,0.4); }
        .stat-icon {
            width: 38px;
            height: 38px;
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .c-blue  .stat-icon { background: var(--blue-bg);  border: 1px solid var(--blue-bd);  color: #60a5fa; }
        .c-green .stat-icon { background: var(--green-bg); border: 1px solid var(--green-bd); color: var(--green); }
        .c-orange.stat-icon { background: var(--accent-dim); border: 1px solid var(--accent-bd); color: var(--accent); }
        .c-orange .stat-icon{ background: var(--accent-dim); border: 1px solid var(--accent-bd); color: var(--accent); }
        .c-red   .stat-icon { background: var(--red-bg);   border: 1px solid var(--red-bd);   color: var(--red); }
        .stat-icon svg { width: 18px; height: 18px; fill: currentColor; }
        .stat-body { flex: 1; min-width: 0; }
        .stat-num {
            font-family: 'Syne', sans-serif;
            font-size: 28px;
            font-weight: 700;
            line-height: 1;
            color: var(--text);
        }
        .stat-lbl {
            font-size: 10.5px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.07em;
            color: var(--text-muted);
            margin-top: 4px;
        }
        .stat-pct {
            font-size: 11px;
            color: var(--text-muted);
            font-family: 'JetBrains Mono', monospace;
            margin-top: 2px;
        }
        
        .toolbar {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 12px;
            animation: fadeUp 0.45s cubic-bezier(.16,1,.3,1) 0.14s both;
        }
        .search-wrap {
            position: relative;
            flex: 1;
            max-width: 320px;
        }
        .search-icon {
            position: absolute;
            left: 11px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted);
            pointer-events: none;
            width: 14px;
            height: 14px;
        }
        .search-input {
            width: 100%;
            padding: 9px 11px 9px 33px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            color: var(--text);
            font-family: 'DM Sans', sans-serif;
            font-size: 13px;
            outline: none;
            transition: border-color 0.18s, box-shadow 0.18s;
        }
        .search-input::placeholder { color: var(--text-muted); }
        .search-input:focus {
            border-color: var(--accent-bd);
            box-shadow: 0 0 0 3px rgba(249,115,22,0.08);
        }
        .filter-group {
            display: flex;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
        }
        .filter-btn {
            padding: 8px 14px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            border: none;
            background: transparent;
            color: var(--text-muted);
            font-family: 'DM Sans', sans-serif;
            letter-spacing: 0.03em;
            transition: all 0.15s;
            border-right: 1px solid var(--border);
            text-transform: uppercase;
        }
        .filter-btn:last-child { border-right: none; }
        .filter-btn:hover      { color: var(--text); background: var(--surface3); }
        .filter-btn.f-all.active   { background: var(--accent-dim);              color: var(--accent);  border-color: transparent; }
        .filter-btn.f-ok.active    { background: rgba(16,185,129,0.1);           color: var(--green);   border-color: transparent; }
        .filter-btn.f-error.active { background: rgba(239,68,68,0.1);            color: var(--red);     border-color: transparent; }
        .result-info {
            font-size: 12px;
            color: var(--text-muted);
            font-family: 'JetBrains Mono', monospace;
            white-space: nowrap;
            margin-left: auto;
        }
        
        .table-outer {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            overflow: hidden;
            box-shadow: var(--tbl-shadow);
            animation: fadeUp 0.45s cubic-bezier(.16,1,.3,1) 0.18s both;
        }
        .table-scroll {
            max-height: calc(100vh - 320px);
            overflow-y: auto;
            overflow-x: auto;
        }
        .table-scroll::-webkit-scrollbar              { width: 5px; height: 5px; }
        .table-scroll::-webkit-scrollbar-track        { background: var(--surface); }
        .table-scroll::-webkit-scrollbar-thumb        { background: var(--border2); border-radius: 3px; }
        .table-scroll::-webkit-scrollbar-thumb:hover  { background: #2a4868; }
        table {
            width: 100%;
            border-collapse: collapse;
            counter-reset: row-index;
        }
        thead th {
            position: sticky;
            top: 0;
            z-index: 10;
            background: var(--surface2);
            border-bottom: 1px solid var(--border);
            padding: 11px 20px;
            text-align: left;
            font-size: 10.5px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.09em;
            color: var(--text-muted);
            white-space: nowrap;
            box-shadow: 0 1px 0 var(--border);
        }
        thead th:not(:first-child) { text-align: center; }
        .th-inner {
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        .th-inner svg { width: 13px; height: 13px; opacity: 0.55; fill: currentColor; }
        tbody tr {
            border-bottom: 1px solid var(--row-border);
            counter-increment: row-index;
            transition: background 0.12s;
        }
        tbody tr:last-child { border-bottom: none; }
        tbody tr:hover td   { background: var(--row-hover); }
        tbody tr.row-hidden { display: none; }
        tbody td {
            padding: 12px 20px;
            font-size: 13px;
            vertical-align: middle;
            text-align: center;
        }
        tbody td:first-child { text-align: left; }
        .stack-cell {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .row-idx {
            font-family: 'JetBrains Mono', monospace;
            font-size: 10px;
            color: var(--text-muted);
            min-width: 22px;
            text-align: right;
            flex-shrink: 0;
        }
        .row-idx::before {
            content: counter(row-index);
        }
        .stack-name {
            font-family: 'JetBrains Mono', monospace;
            font-size: 12.5px;
            font-weight: 500;
            color: var(--text);
            letter-spacing: 0.01em;
        }
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 11px;
            border-radius: 6px;
            font-size: 10.5px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.07em;
            font-family: 'DM Sans', sans-serif;
            border: 1px solid;
            white-space: nowrap;
        }
        .badge.ok {
            background: var(--green-bg);
            color: var(--green);
            border-color: var(--green-bd);
        }
        .badge.error {
            background: var(--red-bg);
            color: var(--red);
            border-color: var(--red-bd);
        }
        .pulse {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            flex-shrink: 0;
        }
        .pulse.green {
            background: var(--green);
            box-shadow: 0 0 0 0 rgba(16,185,129,0.7);
            animation: pulseGreen 2s infinite;
        }
        .pulse.red { background: var(--red); }
        @keyframes pulseGreen {
            0%   { box-shadow: 0 0 0 0   rgba(16,185,129,0.7); transform: scale(0.95); }
            70%  { box-shadow: 0 0 0 5px rgba(16,185,129,0);   transform: scale(1); }
            100% { box-shadow: 0 0 0 0   rgba(16,185,129,0);   transform: scale(0.95); }
        }
        .actions {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            flex-wrap: wrap;
        }
        .action-btn {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 5px 10px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 600;
            text-decoration: none;
            border: 1px solid;
            white-space: nowrap;
            font-family: 'DM Sans', sans-serif;
            letter-spacing: 0.02em;
            transition: all 0.15s;
        }
        .action-btn svg { width: 11px; height: 11px; fill: currentColor; flex-shrink: 0; }
        .btn-nifi {
            background: var(--blue-bg);
            border-color: var(--blue-bd);
            color: #60a5fa;
        }
        .btn-nifi:hover {
            background: rgba(59,130,246,0.16);
            border-color: rgba(59,130,246,0.5);
            box-shadow: 0 0 8px rgba(59,130,246,0.18);
        }
        .btn-api {
            background: rgba(16,185,129,0.07);
            border-color: rgba(16,185,129,0.22);
            color: #34d399;
        }
        .btn-api:hover {
            background: rgba(16,185,129,0.14);
            border-color: rgba(16,185,129,0.45);
        }
        .btn-logs-nifi {
            background: rgba(239,68,68,0.07);
            border-color: rgba(239,68,68,0.22);
            color: #f87171;
        }
        .btn-logs-nifi:hover {
            background: rgba(239,68,68,0.14);
            border-color: rgba(239,68,68,0.45);
        }
        .btn-logs-api {
            background: rgba(249,115,22,0.07);
            border-color: rgba(249,115,22,0.22);
            color: #fb923c;
        }
        .btn-logs-api:hover {
            background: rgba(249,115,22,0.14);
            border-color: rgba(249,115,22,0.45);
        }
        .no-results {
            display: none;
            text-align: center;
            padding: 56px 20px;
            color: var(--text-muted);
        }
        .no-results.visible { display: block; }
        .no-results-icon { font-size: 36px; margin-bottom: 10px; opacity: 0.25; }
        .no-results p { font-size: 13px; }
        
        .footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-top: 14px;
            padding: 0 2px;
            font-size: 11px;
            color: var(--text-muted);
            font-family: 'JetBrains Mono', monospace;
            animation: fadeUp 0.45s cubic-bezier(.16,1,.3,1) 0.22s both;
        }
        .footer-brand {
            display: flex;
            align-items: center;
            gap: 6px;
        }
        
        .theme-toggle {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 38px;
            height: 38px;
            background: var(--surface3);
            border: 1px solid var(--border2);
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.18s ease;
            flex-shrink: 0;
            position: relative;
            overflow: hidden;
        }
        .theme-toggle:hover {
            background: var(--accent-dim);
            border-color: var(--accent-bd);
        }
        .theme-toggle svg {
            width: 17px;
            height: 17px;
            fill: var(--text-sub);
            position: absolute;
            transition: transform 0.4s cubic-bezier(.34,1.56,.64,1), opacity 0.25s ease;
        }
        .theme-toggle:hover svg { fill: var(--accent); }
        .icon-sun  { opacity: 0; transform: rotate(90deg) scale(0.5); }
        .icon-moon { opacity: 1; transform: rotate(0deg) scale(1); }
        [data-theme="light"] .icon-sun  { opacity: 1; transform: rotate(0deg) scale(1); }
        [data-theme="light"] .icon-moon { opacity: 0; transform: rotate(-90deg) scale(0.5); }
    </style>
</head>
<body>
<div class="page-wrap">
    <header class="header">
        <div class="header-left">
            <div class="logo-wrap">
                <img src="logo.png" alt="Iristrace">
            </div>
            <div class="header-title">
                <h1>Iristrace <em>Status</em> Dashboard</h1>
                <div class="header-meta">
                    <span class="live-dot"></span>
                    Última actualización:&nbsp;$FECHA_ACTUAL
                </div>
            </div>
        </div>
        <div class="header-right">
            <div class="badge-total">
                <span class="badge-total-num">$TOTAL_STACKS</span>
                <span class="badge-total-lbl">Stacks</span>
            </div>
            <button class="theme-toggle" id="themeToggle" title="Cambiar tema" onclick="toggleTheme()">
                <svg class="icon-sun" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-12.37l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06c.39-.39.39-1.03 0-1.41s-1.03-.39-1.41 0zM7.05 18.36l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06c.39-.39.39-1.03 0-1.41s-1.03-.39-1.41 0z"/>
                </svg>
                <svg class="icon-moon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.46-.04-.92-.1-1.36-.98 1.37-2.58 2.26-4.4 2.26-2.98 0-5.4-2.42-5.4-5.4 0-1.81.89-3.42 2.26-4.4-.44-.06-.9-.1-1.36-.1z"/>
                </svg>
            </button>
            <button class="refresh-btn" onclick="location.reload()" title="Recargar dashboard">
                <svg class="refresh-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/>
                </svg>
                Actualizar
            </button>
        </div>
    </header>
    <div class="stats-row">
        <div class="stat-card c-blue">
            <div class="stat-icon">
                <svg viewBox="0 0 24 24"><path d="M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z"/></svg>
            </div>
            <div class="stat-body">
                <div class="stat-num" id="s-total">$TOTAL_STACKS</div>
                <div class="stat-lbl">Total Stacks</div>
            </div>
        </div>
        <div class="stat-card c-green">
            <div class="stat-icon">
                <svg viewBox="0 0 24 24"><path d="M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z"/></svg>
            </div>
            <div class="stat-body">
                <div class="stat-num" id="s-nifi-ok">—</div>
                <div class="stat-lbl">NiFi Online</div>
                <div class="stat-pct" id="s-nifi-pct"></div>
            </div>
        </div>
        <div class="stat-card c-orange">
            <div class="stat-icon">
                <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 3c1.93 0 3.5 1.57 3.5 3.5S13.93 13 12 13s-3.5-1.57-3.5-3.5S10.07 6 12 6zm7 13H5v-.23c0-.62.28-1.2.76-1.58C7.47 15.82 9.64 15 12 15s4.53.82 6.24 2.19c.48.38.76.97.76 1.58V19z"/></svg>
            </div>
            <div class="stat-body">
                <div class="stat-num" id="s-api-ok">—</div>
                <div class="stat-lbl">API Saludable</div>
                <div class="stat-pct" id="s-api-pct"></div>
            </div>
        </div>
        <div class="stat-card c-red">
            <div class="stat-icon">
                <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
            </div>
            <div class="stat-body">
                <div class="stat-num" id="s-errors">—</div>
                <div class="stat-lbl">Alertas Activas</div>
                <div class="stat-pct" id="s-errors-sub"></div>
            </div>
        </div>
    </div>
    <div class="toolbar">
        <div class="search-wrap">
            <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input type="text" class="search-input" id="searchInput"
                   placeholder="Buscar stack..." oninput="doFilter()">
        </div>
        <div class="filter-group">
            <button class="filter-btn f-all active"  id="fb-all"   onclick="setFilter('all')">Todos</button>
            <button class="filter-btn f-ok"          id="fb-ok"    onclick="setFilter('ok')">Activos</button>
            <button class="filter-btn f-error"       id="fb-error" onclick="setFilter('error')">Errores</button>
        </div>
        <span class="result-info" id="resultInfo"></span>
    </div>
    <div class="table-outer">
        <div class="table-scroll">
            <table id="mainTable">
                <thead>
                    <tr>
                        <th>
                            <span class="th-inner">
                                <svg viewBox="0 0 24 24"><path d="M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z"/></svg>
                                Stack
                            </span>
                        </th>
                        <th>
                            <span class="th-inner">
                                <svg viewBox="0 0 24 24"><path d="M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z"/></svg>
                                Estado NiFi
                            </span>
                        </th>
                        <th>
                            <span class="th-inner">
                                <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 3c1.93 0 3.5 1.57 3.5 3.5S13.93 13 12 13s-3.5-1.57-3.5-3.5S10.07 6 12 6zm7 13H5v-.23c0-.62.28-1.2.76-1.58C7.47 15.82 9.64 15 12 15s4.53.82 6.24 2.19c.48.38.76.97.76 1.58V19z"/></svg>
                                Estado API
                            </span>
                        </th>
                        <th>
                            <span class="th-inner">
                                <svg viewBox="0 0 24 24"><path d="M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z"/></svg>
                                Accesos Rápidos
                            </span>
                        </th>
                    </tr>
                </thead>
                <tbody id="tableBody">
EOF

TMP_DIR=$(mktemp -d)

for stack in $STACKS; do
    (
        KIBANA_NIFI="https://siem.iristrace.com:5601/app/discover#/?_g=(time:(from:now-24h,to:now))&_a=(query:(language:kuery,query:'%2A${stack}%2A%20AND%20%2Aerror%2A'))"
        KIBANA_API="https://siem.iristrace.com:5601/app/discover#/?_g=(time:(from:now-24h,to:now))&_a=(query:(language:kuery,query:'%2A${stack}%2A%20AND%20%2Aerror%2A'))"

        NIFI_URL="https://nifi-${stack}.iristrace.com"
        NIFI_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$NIFI_URL")

        if [[ "$NIFI_CODE" == "200" || "$NIFI_CODE" == "301" || "$NIFI_CODE" == "302" ]]; then
            NIFI_BADGE="<span class='badge ok'><span class='pulse green'></span>Online</span>"
            NIFI_BTN="<a href=\"$NIFI_URL\" target=\"_blank\" class=\"action-btn btn-nifi\"><svg viewBox='0 0 24 24'><path d='M19 19H5V5h7V3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7h-2v7zM14 3v2h3.59l-9.83 9.83 1.41 1.41L19 6.41V10h2V3h-7z'/></svg>Abrir NiFi</a>"
            NIFI_STATUS="ok"
        else
            NIFI_BADGE="<span class='badge error'><span class='pulse red'></span>Offline</span>"
            NIFI_BTN="<a href=\"$KIBANA_NIFI\" target=\"_blank\" class=\"action-btn btn-logs-nifi\"><svg viewBox='0 0 24 24'><path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z'/></svg>Logs NiFi</a>"
            NIFI_STATUS="error"
        fi

        API_URL="https://api-${stack}.iristrace.com/internal/health"
        API_RESPONSE=$(curl -s --max-time 10 "$API_URL")

        if [[ -n "$API_RESPONSE" ]] && echo "$API_RESPONSE" | grep -q '"result":0'; then
            API_BADGE="<span class='badge ok'><span class='pulse green'></span>Saludable</span>"
            API_BTN="<a href=\"$API_URL\" target=\"_blank\" class=\"action-btn btn-api\"><svg viewBox='0 0 24 24'><path d='M19 19H5V5h7V3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7h-2v7zM14 3v2h3.59l-9.83 9.83 1.41 1.41L19 6.41V10h2V3h-7z'/></svg>Ver API</a>"
            API_STATUS="ok"
        else
            API_BADGE="<span class='badge error'><span class='pulse red'></span>Fallo</span>"
            API_BTN="<a href=\"$KIBANA_API\" target=\"_blank\" class=\"action-btn btn-logs-api\"><svg viewBox='0 0 24 24'><path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z'/></svg>Logs API</a>"
            API_STATUS="error"
        fi

        if [[ "$NIFI_STATUS" == "ok" && "$API_STATUS" == "ok" ]]; then
            ROW_DATA="ok"
        else
            ROW_DATA="error"
        fi

        cat <<ROW_EOF > "$TMP_DIR/${stack}.html"
                <tr data-status="$ROW_DATA" data-name="$stack">
                    <td>
                        <div class="stack-cell">
                            <span class="row-idx"></span>
                            <span class="stack-name">$stack</span>
                        </div>
                    </td>
                    <td>$NIFI_BADGE</td>
                    <td>$API_BADGE</td>
                    <td>
                        <div class="actions">
                            $NIFI_BTN
                            $API_BTN
                        </div>
                    </td>
                </tr>
ROW_EOF
    ) &

    if (( $(jobs -r -p | wc -l) >= $CONCURRENCY_LIMIT )); then
        wait -n
    fi
done

wait

ls "$TMP_DIR"/*.html 1>/dev/null 2>&1 && cat "$TMP_DIR"/*.html >> "$OUTPUT_FILE"

cat <<EOF >> "$OUTPUT_FILE"
                </tbody>
            </table>
            <div class="no-results" id="noResults">
                <div class="no-results-icon">⌕</div>
                <p>No se encontraron stacks con ese criterio de búsqueda</p>
            </div>
        </div>
    </div>
    <footer class="footer">
        <div class="footer-brand">
            Iristrace Systems Monitoring
            <span class="footer-sep">·</span>
            Generado: $FECHA_ACTUAL
        </div>
        <span id="footerCount"></span>
    </footer>
</div>
<script>
(function () {
    function applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('iristrace-theme', theme);
    }
    function toggleTheme() {
        var current = document.documentElement.getAttribute('data-theme') || 'dark';
        applyTheme(current === 'dark' ? 'light' : 'dark');
    }
    (function initTheme() {
        var saved = localStorage.getItem('iristrace-theme') || 'dark';
        applyTheme(saved);
    })();
    window.toggleTheme = toggleTheme;
    var currentFilter = 'all';
    function computeStats() {        var rows   = document.querySelectorAll('#tableBody tr[data-status]');
        var total  = rows.length;
        var nifiOk = 0, apiOk = 0, alerts = 0;
        for (var i = 0; i < rows.length; i++) {
            var badges = rows[i].querySelectorAll('.badge');
            var n = badges[0] && badges[0].classList.contains('ok');
            var a = badges[1] && badges[1].classList.contains('ok');
            if (n) nifiOk++;
            if (a) apiOk++;
            if (!n || !a) alerts++;
        }
        var nifiPct  = total ? Math.round(nifiOk  / total * 100) : 0;
        var apiPct   = total ? Math.round(apiOk   / total * 100) : 0;
        document.getElementById('s-nifi-ok').textContent  = nifiOk;
        document.getElementById('s-nifi-pct').textContent = nifiPct  + '% operativo';
        document.getElementById('s-api-ok').textContent   = apiOk;
        document.getElementById('s-api-pct').textContent  = apiPct   + '% operativo';
        document.getElementById('s-errors').textContent   = alerts;
        document.getElementById('s-errors-sub').textContent = (total - alerts) + ' totalmente OK';
    }
    function doFilter() {
        var query  = document.getElementById('searchInput').value.toLowerCase().trim();
        var rows   = document.querySelectorAll('#tableBody tr[data-status]');
        var shown  = 0;
        for (var i = 0; i < rows.length; i++) {
            var row    = rows[i];
            var name   = row.getAttribute('data-name') || '';
            var status = row.getAttribute('data-status') || '';
            var matchName   = name.indexOf(query) !== -1;
            var matchFilter = (currentFilter === 'all') ||
                              (currentFilter === 'ok'    && status === 'ok') ||
                              (currentFilter === 'error' && status === 'error');
            if (matchName && matchFilter) {
                row.classList.remove('row-hidden');
                shown++;
            } else {
                row.classList.add('row-hidden');
            }
        }
        var infoEl = document.getElementById('resultInfo');
        infoEl.textContent = shown + ' / ' + rows.length + ' stacks';
        var footer = document.getElementById('footerCount');
        if (footer) footer.textContent = shown + ' stacks visibles';
        var noRes = document.getElementById('noResults');
        if (noRes) noRes.classList.toggle('visible', shown === 0);
    }
    function setFilter(f) {
        currentFilter = f;
        var btns = document.querySelectorAll('.filter-btn');
        for (var i = 0; i < btns.length; i++) {
            btns[i].classList.remove('active');
        }
        var target = document.getElementById('fb-' + f);
        if (target) target.classList.add('active');
        doFilter();
    }
    window.doFilter   = doFilter;
    window.setFilter  = setFilter;
    document.addEventListener('DOMContentLoaded', function () {
        computeStats();
        doFilter();
    });
})();
</script>
</body>
</html>
EOF

rm -rf "$TMP_DIR"

echo "Proceso completado."
echo "Dashboard generado en: $OUTPUT_FILE"

if [ -n "\$DISPLAY" ] || [ "\$OSTYPE" == "msys" ] || [ "\$OSTYPE" == "darwin"* ]; then
    if which xdg-open > /dev/null 2>&1; then
        xdg-open "\$OUTPUT_FILE" > /dev/null 2>&1
    elif which open > /dev/null 2>&1; then
        open "\$OUTPUT_FILE" > /dev/null 2>&1
    elif which start > /dev/null 2>&1; then
        start "\$OUTPUT_FILE" > /dev/null 2>&1
    fi
fi
