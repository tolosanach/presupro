# CLAUDE.md — PresuPro Studio

Documentación de arquitectura para desarrollo futuro. Leer antes de modificar cualquier archivo.

---

## Tabla de contenidos

1. [Visión general](#1-visión-general)
2. [Stack tecnológico](#2-stack-tecnológico)
3. [Estructura de archivos](#3-estructura-de-archivos)
4. [Configuración y variables de entorno](#4-configuración-y-variables-de-entorno)
5. [Sistema de autenticación con Google](#5-sistema-de-autenticación-con-google)
6. [Sistema de tracking con Supabase](#6-sistema-de-tracking-con-supabase)
7. [Sistema de email con Resend y Edge Functions](#7-sistema-de-email-con-resend-y-edge-functions)
8. [Sistema freemium y límite de presupuestos](#8-sistema-freemium-y-límite-de-presupuestos)
9. [Integración con MercadoPago](#9-integración-con-mercadopago)
10. [Base de datos — esquema Supabase](#10-base-de-datos--esquema-supabase)
11. [Funciones clave y su ubicación](#11-funciones-clave-y-su-ubicación)
12. [Flujo completo de un presupuesto](#12-flujo-completo-de-un-presupuesto)
13. [Detalles importantes para futuros desarrollos](#13-detalles-importantes-para-futuros-desarrollos)

---

## 1. Visión general

PresuPro Studio es una SPA (Single Page Application) de generación y seguimiento de presupuestos para profesionales y PYMEs. Permite:

- Crear presupuestos con diseño personalizado (logo, colores, tipografía)
- Generar PDF imprimibles directamente en el navegador
- Compartir presupuestos vía link único al cliente
- Rastrear si el cliente vio, aceptó o rechazó el presupuesto
- Gestionar un catálogo de servicios
- Modelo freemium con límite de 10 presupuestos y suscripción via MercadoPago

**Hosting:** GitHub Pages (estático, sin servidor propio).
**Backend:** 100% Supabase (PostgreSQL + Auth + REST API).
**No usa frameworks** — JavaScript vanilla puro.

---

## 2. Stack tecnológico

| Capa | Tecnología | Notas |
|------|-----------|-------|
| Frontend | HTML5 + CSS3 + Vanilla JS | Sin frameworks. ES5-compatible con algunas funciones ES6 |
| Base de datos | Supabase (PostgreSQL) | REST API via fetch. Sin Supabase JS Client en viewer.html |
| Autenticación | Supabase Auth + Google OAuth 2.0 | Solo Google. Sin email/password |
| Hosting | GitHub Pages | Archivos estáticos. HTTPS automático |
| Billing | MercadoPago Subscriptions | Redirect-based checkout. Sin webhooks propios |
| Email | **No implementado** | Hay una referencia a Resend/Edge Functions pero no está construido |
| Iconos | Font Awesome 6.5.0 | CDN |
| Fuentes | Google Fonts (DM Sans, DM Serif Display) | CDN |

---

## 3. Estructura de archivos

```
presupro/
├── index.html          # App principal (admin) — 864 líneas
├── script.js           # Toda la lógica — 2024 líneas
├── viewer.html         # Vista pública para clientes — 724 líneas
├── styles.css          # Estilos completos — 1007 líneas
├── supabase_setup.sql  # Schema de DB y políticas RLS — 113 líneas
├── README.md           # Instrucciones de setup en español
└── .gitignore
```

### index.html — secciones principales

| ID del elemento | Propósito |
|----------------|-----------|
| `app-login-screen` | Pantalla de login con Google |
| `onboarding-overlay` | Modal de primer uso (nombre del negocio) |
| `paywall-overlay` | Modal de upsell al llegar al límite |
| `view-generator` | Formulario de creación + preview en tiempo real |
| `view-history` | Historial de presupuestos guardados con filtros |
| `admin-overlay` | Panel de configuración (7 tabs) |
| `service-overlay` | CRUD de servicios del catálogo |
| `crop-overlay` | Herramienta de recorte de logo (canvas) |
| `confirm-overlay` | Confirmaciones de acciones destructivas |

### script.js — secciones principales

| Líneas | Sección |
|--------|---------|
| 1-33 | Configuración global, variables, tenant isolation |
| 34-79 | Configuración Supabase, funciones base de API |
| 80-153 | Login con Google, logout, estado de sesión |
| 154-225 | Onboarding |
| 226-372 | Inicialización de app, auto-refresh, listeners |
| 373-464 | Renderizado del formulario y preview |
| 465-552 | Items de presupuesto, cálculo de totales |
| 553-651 | Serialización del presupuesto (`collectBudgetData`) |
| 652-857 | Exportación a PDF (`exportPDF`, `buildPrintHTML`) |
| 858-982 | Freemium: `isSubscribed`, `showPaywall`, MercadoPago |
| 983-1088 | Tracking: `generateLink`, `refreshHistoryStatuses` |
| 1089-1212 | Notificaciones (toast, browser notifications) |
| 1213-1372 | Guardado en historial, carga, eliminación |
| 1373-1417 | Sistema de mensajes de WhatsApp |
| 1418-1849 | Panel de administración (admin tabs, servicios, logo) |
| 1850-2003 | Viewer helpers (renderizado del lado del admin) |
| 2004-2024 | Utilidades: `el()`, `fmtNum()`, `escHtml()`, `timeAgo()` |

---

## 4. Configuración y variables de entorno

No hay archivo `.env`. Todas las configuraciones están hardcodeadas en `script.js` y `viewer.html`. Al hacer un fork/deploy nuevo, estos son los valores a actualizar:

### script.js

```javascript
// Línea 46-49 — Proyecto Supabase
var SB = {
  url: 'https://pdkpsbcivgndqhwitrrh.supabase.co',
  key: 'eyJ...'  // Anon key pública (segura con RLS)
};

// Línea 63 — URL de suscripción MercadoPago
var MERCADOPAGO_SUBSCRIPTION_URL = '';
// Ejemplo: 'https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_plan_id=2c938084...'

// Línea 66 — Límite del plan gratuito
var FREE_BUDGET_LIMIT = 10;

// Línea 89 — OAuth redirect (dentro de loginWithGoogle)
redirectTo: 'https://tolosanach.github.io/presupro/'
// Cambiar a la URL del deploy propio

// Línea 106 — Base URL para links del viewer
var VIEWER_BASE_URL = '';
// Ejemplo: 'https://tolosanach.github.io/presupro'
```

### viewer.html

```javascript
// Líneas 357-358
var SUPABASE_URL = 'https://pdkpsbcivgndqhwitrrh.supabase.co';
var SUPABASE_ANON_KEY = 'eyJ...';
```

### Checklist de deploy

1. Crear proyecto en Supabase y ejecutar `supabase_setup.sql`
2. Habilitar Google OAuth en Supabase → Authentication → Providers
3. Agregar la URI de redirect autorizada en Google Cloud Console
4. Actualizar `SB.url` y `SB.key` en `script.js` (líneas 46-49)
5. Actualizar `SUPABASE_URL` y `SUPABASE_ANON_KEY` en `viewer.html` (líneas 357-358)
6. Actualizar `redirectTo` en `loginWithGoogle()` (línea 89)
7. Actualizar `VIEWER_BASE_URL` (línea 106)
8. (Opcional) Crear plan de suscripción en MercadoPago y actualizar línea 63
9. Habilitar GitHub Pages en el repositorio

---

## 5. Sistema de autenticación con Google

### Flujo OAuth

```
Usuario → "Continuar con Google"
  → loginWithGoogle() [script.js:81]
  → sb.auth.signInWithOAuth({ provider: 'google', redirectTo: '...' })
  → Redirige a Google
  → Google redirige de vuelta con código
  → Supabase intercepta y establece sesión en localStorage
  → onAuthStateChange() recibe evento 'SIGNED_IN'
  → onAuthSuccess(session) [script.js:267]
    → Guarda _currentUser y _currentSession
    → updateTenantFromUser() — migra datos de localStorage
    → Verifica si onboarding fue completado
    → loadSubscriptionFromSupabase()
    → initApp()
```

### Aislamiento de tenant (multi-tenant en localStorage)

**Este es el mecanismo más importante para entender la arquitectura:**

Al iniciar la app por primera vez (sin usuario), se genera un ID aleatorio:
```javascript
var _tenantId = 'pp_' + Math.random().toString(36).slice(2, 10);  // línea 7
```

Cuando el usuario hace login, `updateTenantFromUser()` (línea 290) migra todos los datos de localStorage del ID aleatorio al UUID del usuario de Supabase. Esto garantiza que:
- Los datos persisten entre sesiones
- Distintos usuarios en el mismo navegador no se pisan
- El `tenant_id` en Supabase siempre es el UUID del usuario

Todas las claves de localStorage tienen el prefijo del tenant:
```javascript
function _k(name) { return _tenantId + '_' + name; }  // línea 11
```

### Estado de sesión

```javascript
var _currentUser = null;      // Usuario de Supabase (id, email, metadata)
var _currentSession = null;   // Tokens de acceso y refresh

isLoggedIn()    // línea 232 — boolean
appLogout()     // línea 236 — signOut + limpiar pantalla
```

### Token en requests autenticados

`sbFetch()` (línea 52) incluye automáticamente el token de acceso en el header `Authorization: Bearer <token>` cuando hay sesión activa. Esto activa las políticas RLS de `user_profiles`.

---

## 6. Sistema de tracking con Supabase

### Arquitectura de dos tablas

- **`budgets_shared`** — registro del presupuesto compartido y su estado actual
- **`budget_events`** — log de auditoría de cada interacción (visto, aceptado, rechazado)

### Flujo de tracking

**1. Compartir presupuesto** (`generateLink` en script.js:992):
```javascript
// POST a budgets_shared
{
  tenant_id: _tenantId,
  budget_data: <objeto completo del presupuesto>,
  status: 'sent',
  expires_at: <fecha de vencimiento>
}
// Supabase devuelve { id: UUID }
// Se guarda en STATE.history[idx].sbId = UUID
// Se construye URL: VIEWER_BASE_URL + '/viewer.html?id=' + UUID
```

**2. Cliente abre el link** (viewer.html):
- `loadBudget()` — GET a `budgets_shared` por UUID
- `renderDocument()` — renderiza el presupuesto
- `registerView()` — PATCH `status='viewed'`, incrementa `view_count`, guarda timestamps
- POST a `budget_events` con `event_type: 'viewed'` y `user_agent`

**3. Cliente acepta o rechaza**:
- `acceptBudget()` / `confirmReject()` en viewer.html
- PATCH a `budgets_shared`: `status='accepted'` o `status='rejected'`
- POST a `budget_events` con el tipo de evento
- No se vuelve a llamar `registerView()` (guarda en status final)

**4. Admin recibe notificación** (polling en script.js):
```javascript
startAutoRefresh()  // línea 323 — setInterval cada 15 segundos
  → refreshHistoryStatuses()  // línea 1165
  → GET budgets_shared?id=in.(uuid1,uuid2,...)&select=id,status,view_count,last_viewed_at
  → Compara con STATE.history
  → Si cambió: notifyStatusChange() → toast persistente + notificación del browser
```

### Estados del presupuesto

```
sent → viewed → accepted
              ↘ rejected
```

### Detalles de la consulta de refresh

Solo se consultan presupuestos que tienen `sbId` (fueron compartidos). El SELECT es mínimo (solo campos de estado) para mantener la consulta ligera. Ver `refreshHistoryStatuses()` en script.js:1165.

### Seguridad y aislamiento

- Las políticas RLS de `budgets_shared` permiten acceso a `anon` (necesario para que los clientes vean sin login).
- La app del admin filtra siempre por `tenant_id` para solo ver sus propios presupuestos.
- El anon key está en el código fuente (es correcto — es la clave pública de Supabase). La seguridad real la proveen las políticas RLS.

---

## 7. Sistema de email con Resend y Edge Functions

### Estado actual: **NO IMPLEMENTADO**

Hay una referencia en el código (script.js cerca de la línea 1087) que menciona "notificación por email via Supabase", pero no existe implementación real. No hay:
- Configuración de Resend API key
- Supabase Edge Functions creadas
- Templates de email

### Cómo implementarlo en el futuro

La arquitectura recomendada sería:

**1. Crear una Supabase Edge Function** (`supabase/functions/notify-budget/index.ts`):
```typescript
import { Resend } from 'resend';

const resend = new Resend(Deno.env.get('RESEND_API_KEY'));

Deno.serve(async (req) => {
  const { budgetId, event, adminEmail } = await req.json();
  
  await resend.emails.send({
    from: 'presupro@tu-dominio.com',
    to: adminEmail,
    subject: `Tu presupuesto fue ${event}`,
    html: `...template...`
  });
  
  return new Response('ok');
});
```

**2. Llamar la Edge Function desde script.js** cuando el polling detecte un cambio de estado:
```javascript
// En notifyStatusChange() — script.js:1089
fetch('https://tu-proyecto.supabase.co/functions/v1/notify-budget', {
  method: 'POST',
  headers: { 'Authorization': 'Bearer ' + _currentSession.access_token },
  body: JSON.stringify({ budgetId, event: newStatus, adminEmail: _currentUser.email })
});
```

**3. Variables de entorno a configurar en Supabase**:
- `RESEND_API_KEY` — key de Resend

**Alternativa más simple:** Usar un Database Webhook en Supabase que dispare automáticamente al cambiar `status` en `budgets_shared`.

---

## 8. Sistema freemium y límite de presupuestos

### Configuración

```javascript
var FREE_BUDGET_LIMIT = 10;  // script.js:66
```

### Puntos de control

**Al guardar** (`saveBudget()` — script.js:1213):
```javascript
if (STATE.history.length >= FREE_BUDGET_LIMIT && !isSubscribed()) {
  showPaywall();
  return;  // No guarda
}
```

**Advertencia previa** (script.js:1231):
```javascript
var remaining = FREE_BUDGET_LIMIT - STATE.history.length;
if (remaining <= 2 && remaining > 0) {
  toast('Te queda ' + remaining + ' presupuesto(s) gratis');
}
```

### Verificación de suscripción

```javascript
// script.js:862
isSubscribed() {
  var status  = localStorage[_tenantId + '_sub_status'];   // 'active' | 'free'
  var expires = localStorage[_tenantId + '_sub_expires'];  // ISO date string
  
  if (status === 'active') {
    if (!expires) return true;           // Sin fecha = activo para siempre
    return new Date(expires) > new Date();  // Verifica que no expiró
  }
  return false;
}
```

### Badge de estado en el panel de administración

`populateSubscriptionStatus()` (script.js:954) muestra:
- Si activo: "Pro — Activo" con fecha de expiración
- Si free: "X presupuestos restantes de 10"

### Consideración de seguridad

El estado de suscripción vive en **localStorage** (no en Supabase). Esto significa que un usuario técnico podría manipularlo. Si se necesita mayor seguridad, hay que validarlo contra `user_profiles.subscription_status` en Supabase en cada carga de la app. La función `loadSubscriptionFromSupabase()` (script.js:935) ya hace esto — sincroniza desde Supabase al cargar.

---

## 9. Integración con MercadoPago

### Tipo de integración

Redirect-based (sin SDK de MP). El usuario sale de la app, paga en MercadoPago, y vuelve con query params.

### Flujo completo

```
Usuario → "Suscribirse — $30 USD/mes"
  → subscribeMercadoPago() [script.js:886]
  → Construye back_url: app.com/?mp_status=approved&mp_uid=<TENANT_ID>
  → window.location = MERCADOPAGO_SUBSCRIPTION_URL + '&back_url=' + ...
  
  [Usuario paga en MercadoPago]
  
  → MP redirige a back_url con:
    ?mp_status=approved&preapproval_id=YYY&...
    
  → checkMercadoPagoReturn() [script.js:897]
  → Parsea params: mp_status, preapproval_id
  → Si aprobado:
    localStorage[tenant + '_sub_status']  = 'active'
    localStorage[tenant + '_sub_expires'] = now() + 31 días
    localStorage[tenant + '_sub_mp_id']   = preapproval_id
  → saveSubscriptionToSupabase() — sincroniza con user_profiles
  → toast de éxito
  → hidePaywall()
```

### Setup requerido en MercadoPago

1. Crear Plan de Suscripción en el Dashboard de MP
2. Precio: USD $30/mes (o el que se defina)
3. Nombre: "PresuPro Pro"
4. Copiar el `preapproval_plan_id`
5. Construir la URL: `https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_plan_id=<ID>`
6. Pegarla en script.js línea 63

### Renovación

MP maneja los cobros recurrentes automáticamente. La app no implementa renovación propia — cuando expiran los 31 días, el usuario vuelve a ver el paywall. Si hay un webhook de MP, se podría extender automáticamente. Actualmente no hay webhook configurado.

---

## 10. Base de datos — esquema Supabase

Ver el archivo completo en `supabase_setup.sql`. Resumen:

### Tabla `budgets_shared`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | UUID PK | Identificador del presupuesto compartido |
| `tenant_id` | TEXT NOT NULL | UUID del usuario dueño (aislamiento) |
| `budget_data` | JSONB NOT NULL | Objeto completo del presupuesto serializado |
| `status` | TEXT | `sent` / `viewed` / `accepted` / `rejected` |
| `view_count` | INTEGER | Cuántas veces lo abrió el cliente |
| `first_viewed_at` | TIMESTAMPTZ | Primera apertura |
| `last_viewed_at` | TIMESTAMPTZ | Última apertura |
| `created_at` | TIMESTAMPTZ | Cuándo se compartió |
| `expires_at` | TIMESTAMPTZ | Vencimiento del link |

### Tabla `budget_events`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | UUID PK | |
| `budget_id` | UUID FK | Referencia a `budgets_shared.id` (CASCADE DELETE) |
| `event_type` | TEXT | `viewed` / `accepted` / `rejected` |
| `user_agent` | TEXT | Navegador del cliente |
| `created_at` | TIMESTAMPTZ | |

### Tabla `user_profiles`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | UUID PK | = `auth.users.id` |
| `biz_name` | TEXT | Nombre del negocio del onboarding |
| `onboarding_done` | BOOLEAN | Si completó el onboarding |
| `subscription_status` | TEXT | `free` / `active` / `expired` |
| `subscription_expires_at` | TIMESTAMPTZ | |
| `mp_subscription_id` | TEXT | ID de suscripción de MercadoPago |

### Políticas RLS

| Tabla | Role | Operaciones |
|-------|------|-------------|
| `budgets_shared` | `anon` | SELECT, INSERT, UPDATE (todos) |
| `budget_events` | `anon` | SELECT, INSERT |
| `user_profiles` | `authenticated` | Solo el propio registro |

El acceso anon a `budgets_shared` es intencional para que los clientes puedan ver y responder presupuestos sin tener cuenta.

### Trigger

`handle_new_user()` — se ejecuta `AFTER INSERT ON auth.users` y crea automáticamente un registro en `user_profiles`. Está definido en `supabase_setup.sql` líneas 92-106.

---

## 11. Funciones clave y su ubicación

### Autenticación

| Función | Línea | Qué hace |
|---------|-------|----------|
| `loginWithGoogle()` | 81 | Inicia flujo OAuth |
| `onAuthSuccess(session)` | 267 | Setup post-login |
| `updateTenantFromUser()` | 290 | Migra localStorage de ID aleatorio a UUID |
| `isLoggedIn()` | 232 | Boolean |
| `appLogout()` | 236 | Sign out + reset UI |

### Freemium / Suscripción

| Función | Línea | Qué hace |
|---------|-------|----------|
| `isSubscribed()` | 862 | Verifica suscripción activa |
| `showPaywall()` | 872 | Muestra modal de upgrade |
| `subscribeMercadoPago()` | 886 | Redirige a MP |
| `checkMercadoPagoReturn()` | 897 | Procesa vuelta de MP |
| `loadSubscriptionFromSupabase()` | 935 | Sincroniza estado desde DB |
| `populateSubscriptionStatus()` | 954 | Renderiza badge |

### Presupuestos

| Función | Línea | Qué hace |
|---------|-------|----------|
| `collectBudgetData()` | 552 | Serializa el formulario a objeto |
| `calcTotals()` | 540 | Calcula subtotal, descuentos, impuestos |
| `saveBudget()` | 1213 | Guarda en historial (con paywall check) |
| `loadBudgetFromHistory(idx)` | 1246 | Restaura el formulario |
| `deleteBudgetFromHistory(idx)` | 1262 | Elimina entrada |
| `nextBudgetNumber()` | 475 | Devuelve el próximo número autoincremental |

### Tracking / Sharing

| Función | Línea | Qué hace |
|---------|-------|----------|
| `generateLink(idx)` | 992 | Crea registro en Supabase y copia URL |
| `refreshHistoryStatuses()` | 1165 | Polling de estados en Supabase |
| `notifyStatusChange()` | 1089 | Toast + notificación del sistema |
| `startAutoRefresh()` | 323 | Inicia el setInterval de polling |

### PDF

| Función | Línea | Qué hace |
|---------|-------|----------|
| `exportPDF()` | 652 | Orquesta la exportación (WA + print) |
| `buildPrintHTML()` | 678 | Construye HTML completo para imprimir |
| `renderBudgetHTML()` | 563 | Renderiza el cuerpo del presupuesto |
| `buildPDFStyles()` | 734 | CSS específico para impresión |

### Admin panel

| Función | Línea | Qué hace |
|---------|-------|----------|
| `openAdminModal()` | 1420 | Abre panel de configuración |
| `switchAdminTab(tab)` | 1468 | Cambia pestaña del admin |
| `saveBrandConfig()` | 1493 | Guarda colores, logo, tipografía |
| `saveBusinessConfig()` | 1499 | Guarda datos de contacto |
| `saveBudgetConfig()` | 1506 | Guarda prefijo, moneda, validez |
| `saveService()` | 1540 | Crea/actualiza servicio en catálogo |

### Utilidades (líneas 2004-2024)

| Función | Descripción |
|---------|-------------|
| `el(id)` | `document.getElementById()` |
| `elVal(id)` | Valor de un input |
| `setVal(id, val)` | Setea valor de un input |
| `escHtml(str)` | Prevención XSS |
| `fmtNum(n)` | Formatea número: `1234.56` → `"1.234,56"` (es-AR) |
| `fmtDateISO(d)` | Date → `YYYY-MM-DD` |
| `fmtDateDisplay(iso)` | `YYYY-MM-DD` → `DD/MM/YYYY` |
| `timeAgo(isoStr)` | `"hace 2h"`, `"hace un momento"` |

---

## 12. Flujo completo de un presupuesto

```
[1] Admin llena el formulario en index.html
      → Items con precios del catálogo
      → Descuento %, recargo %, impuesto %
      → Datos del cliente
      → calcTotals() recalcula en tiempo real

[2] Admin guarda con "Guardar Presupuesto"
      → saveBudget() [script.js:1213]
      → Verifica paywall: ¿STATE.history.length >= 10 && !isSubscribed()?
      → collectBudgetData() serializa el formulario
      → Agrega al inicio de STATE.history
      → localStorage[KEYS.history] = JSON.stringify(STATE.history)
      → renderHistory()

[3] Admin genera PDF
      → exportPDF() [script.js:652]
      → copyWAMessage(true) — copia WhatsApp al clipboard silenciosamente
      → buildPrintHTML() construye HTML completo con branding
      → Crea iframe invisible, imprime
      → Usuario elige "Guardar como PDF" en el diálogo de impresión

[4] Admin comparte por link
      → generateLink(idx) [script.js:992]
      → POST a Supabase: budgets_shared
      → Recibe { id: UUID }
      → STATE.history[idx].sbId = UUID
      → URL = VIEWER_BASE_URL + '/viewer.html?id=' + UUID
      → Copia al clipboard
      → Card en historial muestra badge "Enviado"

[5] Cliente abre viewer.html?id=UUID
      → loadBudget(): GET budgets_shared por ID
      → Verifica expiración
      → renderDocument(): renderiza el presupuesto completo
      → renderActionBar(): muestra botones Aceptar/Rechazar
      → registerView(): PATCH view_count++, status='viewed'
                        POST budget_events { event_type: 'viewed' }

[6] Cliente acepta o rechaza
      → acceptBudget() o confirmReject()
      → PATCH budgets_shared: status='accepted'/'rejected'
      → POST budget_events
      → UI actualizada (ya no muestra botones)

[7] Admin recibe notificación (polling cada 15s mientras está en Historial)
      → refreshHistoryStatuses() detecta cambio de estado
      → notifyStatusChange(): toast persistente + notificación del browser
      → Card muestra badge "Aceptado" o "Rechazado"
```

---

## 13. Detalles importantes para futuros desarrollos

### Persistencia: localStorage vs Supabase

El historial de presupuestos, la configuración del negocio, el catálogo de servicios y el estado de suscripción viven **principalmente en localStorage**. Supabase se usa para:
- Autenticación (sesión)
- Presupuestos compartidos (`budgets_shared`)
- Perfil de usuario (`user_profiles`) — sincronización secundaria

**Riesgo:** Si el usuario borra localStorage, pierde todo su historial y configuración. No hay sincronización bidireccional de historial con Supabase.

**Para futuros desarrollos** que requieran persistencia robusta, habría que guardar `STATE.history` y `STATE.businessConfig` también en Supabase.

### Sistema de números de presupuesto

Los números se guardan en localStorage como un contador entero. El prefijo es configurable desde el admin. Formato: `<PREFIX>-0001`.

```javascript
nextBudgetNumber()  // Devuelve el próximo número formateado
bumpBudgetNumber()  // Incrementa el contador
```

Si el usuario borra localStorage, el contador se resetea y pueden repetirse números.

### El objeto budget completo

Este es el objeto que se guarda en `STATE.history` y también en `budgets_shared.budget_data`:

```javascript
{
  biz: { name, phone, email, website, address, cuit, paymentTerms, ... },
  brand: { logo, primaryColor, secondaryColor, accentColor, font, ... },
  cfg: { prefix, currency, validityDays, showTax, showDiscount, ... },
  currency: '$',
  client: { name, company, phone, email, address },
  meta: { number: 'PRES-0001', date: '2026-04-13', valid: '2026-04-28' },
  items: [{ svcId, name, qty, price, subtotal, unit, description }],
  totals: { subtotal, discPct, discAmt, surgePct, surgeAmt, taxPct, taxAmt, total },
  notes: 'string',
  savedAt: '2026-04-13T12:34:56Z',  // Agregado en saveBudget()
  sbId: 'UUID'                       // Agregado en generateLink()
}
```

### CSS variables y theming

Los colores del negocio se inyectan como CSS variables en tiempo real. Cuando el admin cambia colores, se actualiza inmediatamente en el preview. En el PDF, los colores se inyectan inline en `buildPDFStyles()`.

Variables principales en `styles.css` (líneas 21-70):
- `--color-primary`, `--color-secondary`, `--color-accent` — colores del negocio
- `--bg-app`, `--bg-surface`, `--bg-surface-2` — superficies
- `--text-main`, `--text-sub`, `--text-muted` — tipografía
- `--header-height: 58px`, `--sidebar-width: 216px` — layout

### Recorte de logo

Herramienta de canvas custom (sin librerías externas). Permite:
- Pan con mouse/touch
- Zoom con rueda del mouse
- Salida como PNG via `canvas.toDataURL()`

El logo se guarda como data URL en `STATE.businessConfig.logo` (localStorage). Si el logo es grande, el localStorage puede llenarse. Límite sugerido: 2MB por archivo fuente (hay validación en `handleLogoUpload()`).

### Notificaciones del browser

Se piden permisos al entrar a la pestaña Historial. Si el usuario los otorga, cuando un presupuesto cambia de estado recibe una notificación nativa del sistema operativo (incluso con la pestaña minimizada).

### Formateo de números

Usar siempre `fmtNum()` para mostrar números monetarios. Usa `toLocaleString('es-AR')` que formatea con puntos y comas estilo argentino: `1.234,56`.

### Seguridad XSS

Usar siempre `escHtml()` (o `esc()` en viewer.html) al insertar strings del usuario en el DOM via `innerHTML`. Nunca insertar directamente datos de `budget_data` sin escapar.

### WhatsApp templates

Hay 3 templates configurables desde el admin. Soportan estas variables:
`{cliente}`, `{numero}`, `{total}`, `{negocio}`, `{fecha}`

Al exportar PDF se copia automáticamente el mensaje de WhatsApp al clipboard (en modo silencioso, sin mostrar toast).

### Tabs del panel de administración

1. **Identidad** — Logo, colores, tipografía, textos de prestigio
2. **Negocio** — Teléfono, email, web, dirección, CUIT, condiciones de pago
3. **Servicios** — CRUD del catálogo de servicios
4. **Presupuesto** — Prefijo, moneda, días de validez, toggles de visibilidad
5. **WhatsApp** — Templates de mensajes
6. **Seguridad** — Info de cuenta, estado de suscripción, botón de logout

### Patrón de fetch a Supabase

La función `sbFetch(method, table, body, query)` en script.js:52 es el wrapper central. Agrega automáticamente:
- `apikey: SB.key` 
- `Authorization: Bearer <token>` (si hay sesión)
- `Content-Type: application/json`
- `Prefer: return=representation` (para obtener el objeto creado en POSTs)

Para consultas complejas, usa `query` como string: `'id=eq.UUID&select=id,status'`.
