# RedTeamAutomation
Automate deployment of Red Team Infra On Azure

GruntHTTP will need adjusting\
Line 61\
ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | SecurityProtocolType.Ssl3 | SecurityProtocolType.Tls;\
Line 858\
ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | SecurityProtocolType.Ssl3 | SecurityProtocolType.Tls;

ToDo\
Add Support For Mythic
Add Phishing and seperate payload infra
