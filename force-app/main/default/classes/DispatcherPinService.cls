public without sharing class DispatcherPinService {

    private static final String PIN_FIELD = 'Dispatcher_Pinned_Ids__c';

    public static void markForDispatcher(String objectApiName, List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }
        String pin = getPinForUser(UserInfo.getUserId());
        if (pin == null) {
            return;
        }

        String objName = resolvePinnableObject(objectApiName);

        String query = 'SELECT Id, ' + PIN_FIELD + ' FROM ' + objName + ' WHERE Id IN :recordIds';
        List<SObject> toPin = Database.query(query);
        List<SObject> toUpdate = new List<SObject>();
        for (SObject rec : toPin) {
            String currentValue = (String) rec.get(PIN_FIELD);
            String newValue = addPin(currentValue, pin);
            if (newValue != currentValue) {
                rec.put(PIN_FIELD, newValue);
                toUpdate.add(rec);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public static Integer clearDispatcherFilter(String objectApiName) {
        String pin = getPinForUser(UserInfo.getUserId());
        if (pin == null) {
            return 0;
        }

        String objName = resolvePinnableObject(objectApiName);

        String likePattern = '%;' + pin + ';%';
        String query = 'SELECT Id, ' + PIN_FIELD + ' FROM ' + objName +
            ' WHERE ' + PIN_FIELD + ' LIKE :likePattern LIMIT 10000';
        List<SObject> toUnpin = Database.query(query);
        List<SObject> toUpdate = new List<SObject>();
        for (SObject rec : toUnpin) {
            String newValue = removePin((String) rec.get(PIN_FIELD), pin);
            rec.put(PIN_FIELD, newValue);
            toUpdate.add(rec);
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        return toUpdate.size();
    }

    // Validates the object exists and carries the pin field, returning its canonical API name
    // so the dynamic SOQL is never built from raw client input.
    private static String resolvePinnableObject(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API Name is required');
        }
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) {
            throw new AuraHandledException('Object not found: ' + objectApiName);
        }
        Schema.DescribeSObjectResult describe = objType.getDescribe();
        if (!describe.fields.getMap().containsKey(PIN_FIELD)) {
            throw new AuraHandledException(
                'El objeto ' + describe.getName() + ' no tiene el campo ' + PIN_FIELD +
                '. Créalo para poder usar el pin de despachador en este objeto.'
            );
        }
        return describe.getName();
    }

    // Returns the ;N; token for the current user's pin, or null if no record found.
    private static String getPinForUser(String userId) {
        List<Dispatcher_Pin__mdt> pins = [
            SELECT Pin_Value__c
            FROM Dispatcher_Pin__mdt
            WHERE User_Id__c = :userId
            LIMIT 1
        ];
        if (pins.isEmpty()) {
            return null;
        }
        return String.valueOf(Integer.valueOf(pins[0].Pin_Value__c));
    }

    // Stores as ;N; — leading and trailing semicolons ensure ;10; never matches ;100;.
    private static String addPin(String currentValue, String pin) {
        String token = ';' + pin + ';';
        if (String.isBlank(currentValue)) {
            return token;
        }
        if (currentValue.contains(token)) {
            return currentValue;
        }
        // Strip trailing ; before appending so we get ;a;;b; -> ;a;b;
        return currentValue.removeEnd(';') + token;
    }

    private static String removePin(String currentValue, String pin) {
        if (String.isBlank(currentValue)) {
            return null;
        }
        String token = ';' + pin + ';';
        String result = currentValue.replace(token, ';');
        // Clean up a lone ; or empty string
        if (result == ';' || result == '') {
            return null;
        }
        return result;
    }
}
