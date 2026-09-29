# 🔍 Buscador Dinámico de Salesforce

Sistema configurable de búsqueda dinámica para Salesforce que permite crear filtros personalizados sin código. Especialmente diseñado para Field Service Dispatcher Console.

## 🎯 Características Principales

- ✅ **Grid Responsive de Filtros**: Los campos se organizan automáticamente en filas y columnas
- ✅ **Search Layout Automático**: Las columnas de resultados se toman del Search Layout del objeto
- ✅ **Multi-búsqueda**: Buscar múltiples valores separados por espacios
- ✅ **Navegación a List View**: Botón opcional para ver resultados en list view estándar
- ✅ **Quick Actions Nativas**: Usa las quick actions y global actions configuradas en el objeto
- ✅ **Sin Código**: Configuración 100% declarativa

## 🏗️ Arquitectura

### Objetos Principales

**Filter_Configuration__c**
- Configuración principal del buscador
- Define el objeto a buscar y layout del grid
- Nuevo campo: `List_View_API_Name__c` para navegación

**Filter_Field__c**
- Campos que aparecen como filtros
- Soporta multi-búsqueda
- Order__c define el orden en el grid

### Componentes LWC

**dynamicFilterSearch**
- Grid responsive de filtros (basado en Grid_Columns__c)
- Tabla de resultados con links a registros
- Botón "Ver en List View" (opcional)
- Botón "Limpiar" filtros

**filterConfigurationBuilder**
- Constructor visual de configuraciones
- Permite arrastrar y soltar campos

### Apex Classes

**DynamicFilterController**
- Controlador principal
- Método `getSearchLayoutFields()` para obtener campos del Search Layout
- Método `searchRecords()` ejecuta búsquedas dinámicas

**DynamicFilterService**
- Lógica de negocio
- Construcción dinámica de SOQL
- Usa Search Layout automáticamente para columnas

## 📦 Instalación

Ver [INSTRUCCIONES_DESPLIEGUE.md](INSTRUCCIONES_DESPLIEGUE.md)

```bash
# Nuevo deployment
sf project deploy start --manifest buscador.xml --target-org mi-org

# Actualización (incluye eliminación de objetos obsoletos)
sf project deploy start --manifest buscador.xml --target-org mi-org
sf project deploy start --manifest destructiveChanges.xml --pre-destructive-changes --target-org mi-org
```

## 🚀 Uso Rápido

Ver [GUIA_USO_BUSCADOR_DINAMICO.md](GUIA_USO_BUSCADOR_DINAMICO.md)

### 1. Crear Configuración

```
Objeto: Filter_Configuration__c
- Label: "Búsqueda de Service Appointments"
- Object API Name: "ServiceAppointment"
- Grid Columns: 3
- List View API Name: "All_ServiceAppointments" (opcional)
```

### 2. Añadir Campos de Filtro

```
Filter_Field__c (Order 1):
- Field API Name: "Status"
- Field Label: "Estado"
- Field Type: "Picklist"
- Is Multi Search: ✓

Filter_Field__c (Order 2):
- Field API Name: "SchedStartTime"
- Field Label: "Fecha Inicio"
- Field Type: "DateTime"
```

### 3. Añadir a Página

Lightning App Builder → Añadir componente `dynamicFilterSearch`

## 🎨 Ejemplo de Grid

Con `Grid_Columns__c = 3` y 4 campos:

```
┌─────────────┬─────────────┬─────────────┐
│  Campo 1    │  Campo 2    │  Campo 3    │
├─────────────┴─────────────┴─────────────┤
│  Campo 4    │                           │
└─────────────┴───────────────────────────┘
```

## 🔄 Cambios de Versión

### v2.0 (Actual)

**Eliminado:**
- Objeto `Bulk_Action__c` (usar Quick Actions nativas)
- Objeto `Display_Column__c` (usar Search Layout automático)
- Modo DataTable con checkboxes

**Añadido:**
- Grid CSS responsive para filtros
- Uso automático de Search Layout
- Campo `List_View_API_Name__c`
- Botón "Limpiar" filtros

**Mejorado:**
- Performance (menos objetos y queries)
- UX más simple y estándar de Salesforce
- Integración perfecta con Dispatcher Console

## 🏢 Caso de Uso: Field Service Dispatcher

El buscador se integra perfectamente con Field Service Dispatcher Console:

1. Dispatcher abre la consola
2. Debajo aparece la list view de Service Appointments
3. Usa el buscador dinámico para filtrar
4. Resultados se muestran en tabla
5. Clic en registro abre en la consola
6. Quick actions disponibles en el registro

## 📊 Metadata Incluida

- **2 Custom Objects**: Filter_Configuration__c, Filter_Field__c
- **2 LWC Components**: dynamicFilterSearch, filterConfigurationBuilder
- **3 Apex Classes**: Controller, Service, BuilderController
- **1 Permission Set**: Dynamic_Filter_User
- **1 Custom App**: Dynamic Filter Manager

## 🔐 Seguridad

- **USER_MODE** en todas las queries
- **Field Level Security** respetada
- **Object Permissions** validadas
- **Permission Set** incluido

## 🧪 Testing

```bash
# Ejecutar tests
sf apex run test --class-names DynamicFilterServiceTest --target-org mi-org --result-format human
```

Coverage: ~85%

## 📝 Documentación Adicional

- [GUIA_USO_BUSCADOR_DINAMICO.md](GUIA_USO_BUSCADOR_DINAMICO.md) - Guía paso a paso
- [INSTRUCCIONES_DESPLIEGUE.md](INSTRUCCIONES_DESPLIEGUE.md) - Instrucciones de deployment
- [SOLUCION_FIELD_SERVICE_INTEGRACION.md](SOLUCION_FIELD_SERVICE_INTEGRACION.md) - Integración con Field Service

## 🤝 Contribuir

Este es un proyecto interno. Para mejoras o bugs, contacta al equipo de desarrollo.

## 📄 Licencia

Uso interno de la organización.

---

**Versión**: 2.0  
**Última actualización**: 2026-07-06  
**Salesforce API**: v60.0