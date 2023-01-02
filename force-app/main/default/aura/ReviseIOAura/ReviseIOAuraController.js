({
    revise : function(component, event, helper) {
        component.find('lWCComponent2').handleRevise ();   
    },
    closeModal : function(component,event,helper)
    {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire(); 
    }
})