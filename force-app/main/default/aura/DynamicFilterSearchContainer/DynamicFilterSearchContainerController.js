({
    doInit: function(component, event, helper) {
        var action = component.get("c.getDefaultConfigurationName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var configName = response.getReturnValue();
                if (configName) {
                    component.set("v.configurationName", configName);
                }
            }
            component.set("v.isLoaded", true);
        });
        $A.enqueueAction(action);
    }
})
