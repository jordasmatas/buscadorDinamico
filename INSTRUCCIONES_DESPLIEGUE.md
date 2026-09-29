# Instrucciones de Despliegue - Buscador Dinámico

## 📋 Prerequisitos

- Salesforce CLI instalado (`sf`)
- Autenticación con la org destino
- Permisos de administrador en la org

## 🚀 Despliegue Inicial (Nueva Instalación)

### Paso 1: Autenticar con la Org

```bash
sf org login web --alias mi-org
```

### Paso 2: Desplegar Metadata

```bash
sf project deploy start --manifest buscador.xml --target-org mi-org
```

### Paso 3: Asignar Permission Set

```bash
sf org assign permset --name Dynamic_Filter_User --target-org mi-org
```

## 🔄 Actualización desde Versión Anterior

Si ya tienes una versión anterior del buscador desplegada, sigue estos pasos:

### Paso 1: Desplegar Nueva Metadata

```bash
sf project deploy start --manifest buscador.xml --target-org mi-org
```

### Paso 2: Eliminar Metadata Obsoleta

⚠️ **IMPORTANTE**: Este paso elimina los objetos `Bulk_Action__c` y `Display_Column__c` que ya no se usan.

```bash
sf project deploy start --manifest destructiveChanges.xml --pre-destructive-changes --target-org mi-org
```

### Paso 3: Limpiar Datos (Opcional)

Los registros de `Bulk_Action__c` y `Display_Column__c` se eliminarán automáticamente con el paso anterior.

## 📝 Cambios en esta Versión

### Eliminados:
- ❌ Objeto `Bulk_Action__c` (usar Quick Actions nativas)
- ❌ Objeto `Display_Column__c` (usar Search Layout automáticamente)
- ❌ Modo DataTable
- ❌ Clases `BulkActionHandler` y `ServiceAppointmentAssignmentAction`

### Añadidos:
- ✅ Campo `List_View_API_Name__c` en Filter_Configuration__c
- ✅ Grid responsive para campos de filtro
- ✅ Uso automático de Search Layout para columnas
- ✅ Botón "Ver en List View"

### Modificados:
- 🔄 `Display_Mode__c` solo tiene opción "ListView"
- 🔄 Grid de filtros con filas/columnas automáticas
- 🔄 Tabla de resultados sin checkboxes

## 🧪 Verificación Post-Despliegue

### 1. Verificar Objetos

```bash
sf data query --query "SELECT Id, Label__c FROM Filter_Configuration__c LIMIT 5" --target-org mi-org
```

### 2. Verificar Permission Set

```bash
sf org list permset --target-org mi-org | grep "Dynamic_Filter_User"
```

### 3. Probar en la UI

1. Navega a la App "Dynamic Filter Manager"
2. Abre un registro de Filter Configuration
3. Verifica que el campo "List View API Name" esté visible
4. Prueba el componente en una página

## 🔧 Troubleshooting

### Error: "Component not found"

Limpiar caché del navegador:
```
Ctrl + Shift + R (Windows/Linux)
Cmd + Shift + R (Mac)
```

### Error al eliminar Bulk_Action__c

Si hay dependencias, elimina manualmente:
1. Setup → Object Manager → Bulk Action
2. Delete all records
3. Delete the object

### Error: "Field does not exist"

Verifica que el deployment se completó:
```bash
sf project deploy start --manifest buscador.xml --target-org mi-org --dry-run
```

## 📊 Estadísticas del Despliegue

### Metadata Incluida:
- 2 Custom Objects (Filter_Configuration__c, Filter_Field__c)
- 1 Lightning Web Component (dynamicFilterSearch)
- 1 Lightning Web Component (filterConfigurationBuilder)
- 3 Apex Classes
- 1 Permission Set
- 1 Custom Application
- Tabs, Fields, Layouts

### Tiempo Estimado:
- Despliegue inicial: 2-3 minutos
- Actualización: 3-5 minutos (incluye destructive changes)

## 🆘 Soporte

Si encuentras problemas durante el despliegue:

1. Revisa los logs de despliegue
2. Verifica los permisos de usuario
3. Consulta la guía de uso: `GUIA_USO_BUSCADOR_DINAMICO.md`