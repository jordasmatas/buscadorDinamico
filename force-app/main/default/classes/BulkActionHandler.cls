/**
 * Interface for implementing custom bulk actions on filtered records.
 * Classes implementing this interface can be invoked from the Dynamic Filter component.
 */
public interface BulkActionHandler {
    
    /**
     * Executes the bulk action on the provided record Ids.
     * @param recordIds List of record Ids to process
     * @param params Additional parameters for the action (e.g., assignment values, status updates)
     * @example
     * public void execute(List<Id> recordIds, Map<String, Object> params) {
     *     Id resourceId = (Id) params.get('resourceId');
     *     // Process records...
     * }
     */
    void execute(List<Id> recordIds, Map<String, Object> params);
}