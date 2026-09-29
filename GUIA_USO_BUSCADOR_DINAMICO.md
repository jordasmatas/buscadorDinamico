# Guía Paso a Paso - Buscador Dinámico de Salesforce v2.0

## 📋 Índice
1. [Despliegue Inicial](#1-despliegue-inicial)
2. [Configuración del Buscador](#2-configuración-del-buscador)
3. [Añadir el Componente a una Página](#3-añadir-el-componente-a-una-página)
4. [Uso del Buscador](#4-uso-del-buscador)

---

## 1. Despliegue Inicial

### Paso 1.1: Desplegar los Metadatos
```bash
sf project deploy start --manifest buscador.xml --target-org tu-org-alias
```

### Paso 1.2: Asignar Permission Set

1. **Setup → Permission Sets**
2. Buscar: "Dynamic Filter User"
3. **Manage Assignments → Add Assignments**
4. Seleccionar usuarios
5. **Assign**

---

## 2. Configuración del Buscador

### Paso 2.1: Crear una Configuración de Filtro

1. **App Launcher → "Filter Configurations"**
2. **New**
3. Completar:
   - **Label**: `Búsqueda de Service Appointments`
   - **Object API Name**: `ServiceAppointment`
   - **Grid Columns**: `3` (campos por fila)
   - **List View API Name**: `All_ServiceAppointments` (opcional)
   - **Active**: ✅
4. **Save**

### Paso 2.2: Añadir Campos de Filtro

Los campos que añadas aquí serán los que aparezcan en el grid de filtros.

#### Ejemplo Campo 1: Status
- **Field API Name**: `Status`
- **Field Label**: `Estado`
- **Field Type**: `Picklist`
- **Order**: `1`
- **Is Multi Search**: ✅ (buscar múltiples: "Scheduled Dispatched")

#### Ejemplo Campo 2: Fecha Inicio
- **Field API Name**: `SchedStartTime`
- **Field Label**: `Fecha Inicio Programada`
- **Field Type**: `DateTime`
- **Order**: `2`

#### Ejemplo Campo 3: Número de Cita
- **Field API Name**: `AppointmentNumber`
- **Field Label**: `Número de Cita`
- **Field Type**: `Text`
- **Order**: `3`

#### Ejemplo Campo 4: Recurso
- **Field API Name**: `ServiceResourceId`
- **Field Label**: `Recurso de Servicio`
- **Field Type**: `Lookup`
- **Order**: `4`

**💡 Grid Layout**: Con `Grid Columns = 3`:
- Campos 1, 2, 3 → Fila 1
- Campo 4 → Fila 2

---

## 3. Añadir el Componente a una Página

### Opción A: Lightning App Builder

1. **Setup → Lightning App Builder → New**
2. Crear "App Page"
3. Nombre: "Buscador de Service Appointments"
4. Seleccionar template
5. Arrastrar componente **dynamicFilterSearch**
6. **Save → Activate**

### Opción B: Dispatcher Console (Recomendado para Field Service)

1. **Setup → App Manager**
2. Editar "Field Service Dispatcher"
3. **Lightning App Builder**
4. Añadir **dynamicFilterSearch** en utility bar o panel inferior
5. **Save → Activate**

---

## 4. Uso del Buscador

### Paso 4.1: Abrir el Buscador

1. Navegar a la página donde añadiste el componente
2. Ver el componente "Buscador Dinámico"

### Paso 4.2: Expandir Panel de Búsqueda

1. Clic en **"Búsqueda Avanzada"**
2. Se expande el panel con los filtros

### Paso 4.3: Aplicar Filtros

**Grid de Filtros** (ejemplo con 3 columnas):
```
┌─────────────┬─────────────┬─────────────┐
│   Estado    │    Fecha    │   Número    │
│ [Scheduled] │ [07/06/26]  │  [SA-001]   │
├─────────────┴─────────────┴─────────────┤
│   Recurso   │                           │
│ [John Doe]  │                           │
└─────────────┴───────────────────────────┘
```

**Multi-búsqueda**:
- Campo Status: `Scheduled Dispatched` (busca ambos valores)
- Usa espacio como separador

### Paso 4.4: Buscar

1. **Clic en "Buscar"**
2. Resultados aparecen en tabla debajo
3. Mensaje: "15 registros encontrados"

### Paso 4.5: Ver Resultados

**Columnas Automáticas**:
Las columnas se toman automáticamente del **Search Layout** del objeto.

**Tabla de Resultados**:
- Links a registros (clic abre el registro)
- Sin checkboxes (no hay bulk actions)
- Botón "Ver en List View" (si configurado)

### Paso 4.6: Acciones sobre Registros

**Quick Actions**:
1. Clic en un registro para abrirlo
2. Quick actions disponibles en la parte superior del registro
3. Global actions disponibles desde el menú

**Ver en List View** (opcional):
1. Si configuraste `List_View_API_Name__c`
2. Clic en botón "Ver en List View"
3. Navega a la list view estándar de Salesforce

### Paso 4.7: Limpiar Filtros

1. **Clic en "Limpiar"**
2. Todos los filtros se resetean
3. Resultados se limpian

---

## 🎯 Ejemplos de Uso

### Ejemplo 1: Buscar por Estado Múltiple

**Configuración**:
- Campo: Status
- Is Multi Search: ✅

**Búsqueda**:
```
Status: Scheduled Dispatched Completed
```

**Resultado**: Registros con Status = Scheduled OR Dispatched OR Completed

### Ejemplo 2: Buscar por Rango de Fechas

**Configuración**:
- Campo 1: SchedStartTime (>=)
- Campo 2: SchedEndTime (<=)

**Búsqueda**:
```
Fecha Inicio: 2026-07-01
Fecha Fin: 2026-07-31
```

### Ejemplo 3: Field Service Dispatcher

**Escenario**: Dispatcher necesita ver citas de hoy para un recurso específico.

**Búsqueda**:
```
Estado: Scheduled Dispatched
Fecha: 2026-07-06
Recurso: John Smith
```

**Resultado**: 8 citas encontradas
**Acción**: Clic en una cita → Se abre en la consola → Usar quick action "Complete Appointment"

---

## 💡 Tips y Mejores Prácticas

### Grid Layout

- **3 columnas**: Ideal para desktop (1920x1080)
- **2 columnas**: Mejor para laptops (1366x768)
- **4+ columnas**: Solo para monitores grandes

### Search Layout

Las columnas mostradas vienen del Search Layout del objeto. Para personalizarlas:

1. **Setup → Object Manager → [Tu Objeto]**
2. **Search Layouts → Search Results**
3. **Edit** y selecciona las columnas
4. Las columnas aparecerán automáticamente en el buscador

### Multi-búsqueda

Útil para:
- Estados múltiples
- Tipos de registro
- Categorías
- Nombres parciales

### List View API Name

Para obtener el API name de una list view:

1. Abre la list view en Salesforce
2. URL: `/lightning/o/ServiceAppointment/list?filterName=00B...`
3. El `filterName` es el ID, no el API name
4. Para API name, ve a Setup → Object Manager → List Views

---

## 🔧 Troubleshooting

### No veo resultados

1. Verifica que los filtros tengan valores
2. Verifica permisos sobre el objeto
3. Verifica que el Field API Name sea correcto

### Las columnas no son las esperadas

- Las columnas vienen del **Search Layout** del objeto
- Edita el Search Layout para cambiar columnas

### El grid no se ve bien

- Ajusta `Grid_Columns__c` según tu pantalla
- En móvil siempre será 1 columna

### Botón "Ver en List View" no aparece

- Verifica que `List_View_API_Name__c` esté configurado
- Verifica que la list view exista

---

## 📊 Límites y Consideraciones

- **Máximo registros**: 2000 por búsqueda
- **Timeout**: 120 segundos
- **FLS**: Respeta Field Level Security
- **Sharing**: Respeta Object/Record sharing

---

## 🚀 Próximos Pasos

Una vez dominada la configuración básica:

1. Crea múltiples configuraciones para diferentes objetos
2. Configura list views personalizadas
3. Añade el componente a diferentes páginas
4. Entrena a tu equipo en el uso

---

**¿Necesitas ayuda?** Contacta a tu administrador de Salesforce.

**Documentación**: Ver `README_BUSCADOR_DINAMICO.md` para detalles técnicos
