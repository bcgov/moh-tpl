global class KeycloakScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        
        KeycloakSchedulerService.RegistrationScheduler(SC);
        
    }
}