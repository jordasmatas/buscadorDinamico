@isTest
private class DynamicFilterPicklistHelperTest {
    @isTest
    static void shouldReturnOptions_WhenIndependentPicklist() {
        // Given / When
        Test.startTest();
        DynamicFilterPicklistHelper.PicklistFieldInfo info =
            DynamicFilterPicklistHelper.getPicklistFieldInfo('Account', 'Industry');
        Test.stopTest();

        // Then
        Assert.isNull(info.controllingFieldApiName, 'Industry has no controlling field');
        Assert.isFalse(info.options.isEmpty(), 'Industry should return picklist options');
        for (DynamicFilterPicklistHelper.DependentPicklistOption option : info.options) {
            Assert.isTrue(option.validFor.isEmpty(), 'Independent options have no validFor entries');
        }
    }

    @isTest
    static void shouldThrow_WhenObjectApiNameBlank() {
        // When / Then
        Test.startTest();
        try {
            DynamicFilterPicklistHelper.getPicklistFieldInfo('', 'Industry');
            Assert.fail('Expected AuraHandledException for blank object API name');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception should carry a message');
        }
        Test.stopTest();
    }

    @isTest
    static void shouldThrow_WhenObjectNotFound() {
        // When / Then
        Test.startTest();
        try {
            DynamicFilterPicklistHelper.getPicklistFieldInfo('Not_A_Real_Object__x', 'Industry');
            Assert.fail('Expected AuraHandledException for unknown object');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception should carry a message');
        }
        Test.stopTest();
    }

    @isTest
    static void shouldThrow_WhenFieldNotFound() {
        // When / Then
        Test.startTest();
        try {
            DynamicFilterPicklistHelper.getPicklistFieldInfo('Account', 'Not_A_Real_Field__c');
            Assert.fail('Expected AuraHandledException for unknown field');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Exception should carry a message');
        }
        Test.stopTest();
    }

    @isTest
    static void shouldConvertDecimalToBinary() {
        // When / Then
        Assert.areEqual('10011', DynamicFilterPicklistHelper.decimalToBinary(19), '19 should convert to 10011');
        Assert.areEqual('', DynamicFilterPicklistHelper.decimalToBinary(0), '0 should convert to empty string');
        Assert.areEqual('1', DynamicFilterPicklistHelper.decimalToBinary(1), '1 should convert to 1');
    }

    @isTest
    static void shouldDecodeBase64ToBits() {
        // When
        String bits = DynamicFilterPicklistHelper.base64ToBits('gAAA');

        // Then: 'g' is index 32 -> 100000, each 'A' is index 0 -> 000000
        Assert.areEqual('100000000000000000000000', bits, 'gAAA should decode to the expected 24-bit string');
        Assert.areEqual('', DynamicFilterPicklistHelper.base64ToBits(''), 'Blank token should decode to empty string');
        Assert.areEqual('', DynamicFilterPicklistHelper.base64ToBits(null), 'Null token should decode to empty string');
    }
}
