({
    openModal : function(component) {
        $A.createComponent(
            'c:DynamicFilterSearchServiceTerritoryModalBody',
            {},
            function(content, status, errorMessage) {
                if (status === 'SUCCESS') {
                    component.find('overlayLib').showCustomModal({
                        header: 'Búsqueda avanzada',
                        body: content,
                        showCloseButton: true,
                        cssClass: 'slds-modal_large dfs-overlay-modal'
                    });
                } else {
                    // eslint-disable-next-line no-console
                    console.error('Error creating DynamicFilterSearch modal body:', errorMessage);
                }
            }
        );
    }
})
