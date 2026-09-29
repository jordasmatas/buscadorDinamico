/**
 * Example implementation of BulkActionHandler for assigning Service Appointments to Service Resources.
 * This class demonstrates how to create custom bulk actions for the Dynamic Filter component.
 */
public without sharing class ServiceAppointmentAssignmentAction implements BulkActionHandler {
    
    /**
     * Assigns multiple Service Appointments to a Service Resource.
     * @param recordIds List of ServiceAppointment Ids
     * @param params Map containing 'resourceId' key with the target Service Resource Id
     * @example
     * Map<String, Object> params = new Map<String, Object>{'resourceId' => '0Hn...'};
     * new ServiceAppointmentAssignmentAction().execute(appointmentIds, params);
     */
    public void execute(List<Id> recordIds, Map<String, Object> params) {
        if (recordIds == null || recordIds.isEmpty()) {
            throw new ServiceAppointmentAssignmentException('No Service Appointments provided');
        }
        
        if (params == null || !params.containsKey('resourceId')) {
            throw new ServiceAppointmentAssignmentException('Resource ID is required');
        }
        
        Id resourceId = (Id) params.get('resourceId');
        if (String.isBlank(String.valueOf(resourceId))) {
            throw new ServiceAppointmentAssignmentException('Invalid Resource ID');
        }
        
        // Validate Service Resource access
        if (!Schema.sObjectType.ServiceResource.isAccessible()) {
            throw new ServiceAppointmentAssignmentException('No access to Service Resource');
        }
        
        // Validate Service Appointments access
        if (!Schema.sObjectType.ServiceAppointment.isAccessible() || 
            !Schema.sObjectType.ServiceAppointment.isUpdateable()) {
            throw new ServiceAppointmentAssignmentException('No access to update Service Appointments');
        }
        
        // Query Service Appointments
        List<ServiceAppointment> appointments = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Id IN :recordIds
            WITH SYSTEM_MODE
        ];
        
        if (appointments.isEmpty()) {
            throw new ServiceAppointmentAssignmentException('No Service Appointments found');
        }
        
        // Create or update Service Resources assignments
        List<AssignedResource> assignedResources = new List<AssignedResource>();
        Map<Id, AssignedResource> existingAssignments = getExistingAssignments(recordIds, resourceId);
        
        for (ServiceAppointment apt : appointments) {
            if (!existingAssignments.containsKey(apt.Id)) {
                assignedResources.add(new AssignedResource(
                    ServiceAppointmentId = apt.Id,
                    ServiceResourceId = resourceId
                ));
            }
        }
        
        if (!assignedResources.isEmpty()) {
            Database.SaveResult[] results = Database.insert(assignedResources, false);
            handleSaveResults(results);
        }
    }
    
    /**
     * Retrieves existing resource assignments for the given appointments and resource.
     */
    private Map<Id, AssignedResource> getExistingAssignments(List<Id> appointmentIds, Id resourceId) {
        Map<Id, AssignedResource> assignmentMap = new Map<Id, AssignedResource>();
        
        if (!Schema.sObjectType.AssignedResource.isAccessible()) {
            return assignmentMap;
        }
        
        List<AssignedResource> existing = [
            SELECT Id, ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :appointmentIds
            AND ServiceResourceId = :resourceId
            WITH SYSTEM_MODE
        ];
        
        for (AssignedResource ar : existing) {
            assignmentMap.put(ar.ServiceAppointmentId, ar);
        }
        
        return assignmentMap;
    }
    
    /**
     * Processes Database.SaveResult and collects errors.
     */
    private void handleSaveResults(Database.SaveResult[] results) {
        List<String> errors = new List<String>();
        Integer successCount = 0;
        
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                for (Database.Error error : result.getErrors()) {
                    errors.add(error.getMessage());
                }
            }
        }
        
        if (!errors.isEmpty()) {
            String errorMessage = 'Assigned ' + successCount + ' of ' + results.size() + 
                                ' appointments. Errors: ' + String.join(errors, '; ');
            throw new ServiceAppointmentAssignmentException(errorMessage);
        }
    }
    
    /**
     * Custom exception for assignment errors.
     */
    public class ServiceAppointmentAssignmentException extends Exception {}
}