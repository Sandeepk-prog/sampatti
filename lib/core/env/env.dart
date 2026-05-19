import 'package:envied/envied.dart';
part 'env.g.dart';
@Envied(path:'.env')
abstract class Env {

@EnviedField(varName: "firebaseAppId")
static const String firebaseAppId=_Env.firebaseAppId;
@EnviedField(varName:"firebaseAPIKey")
static const String firebaseAPIKey=_Env.firebaseAPIKey;
@EnviedField(varName:"senderId")
static const String senderId=_Env.senderId;
@EnviedField(varName:"projectId")
static const String projectId=_Env.projectId;
@EnviedField(varName:"sandboxCASAPIKey")
static const String sandboxCASApiKey=_Env.sandboxCASApiKey;
@EnviedField(varName:"supabaseAPIKey")
static const String supabaseAPIKey=_Env.supabaseAPIKey;
@EnviedField(varName:"supabaseProjectId")
static const String supabaseProjectId=_Env.supabaseProjectId;
@EnviedField(varName:"supabaseProjectURL")
static const String supabaseProjectURL=_Env.supabaseProjectURL;
@EnviedField(varName:"prodCASAPIKey")
static const String prodCASAPIKey=_Env.prodCASAPIKey;

@EnviedField(varName:"cloudinaryAPIKey")
static const String cloudinaryAPIKey=_Env.cloudinaryAPIKey;
@EnviedField(varName:"cloudinarySecretKey")
static const String cloudinarySecretKey=_Env.cloudinarySecretKey;
@EnviedField(varName:"cloudinaryName")
static const String cloudinaryName=_Env.cloudinaryName;




}