package it.tdlight.client;

import it.tdlight.common.ExceptionHandler;
import it.tdlight.common.TelegramClient;
import it.tdlight.jni.TdApi;
import it.tdlight.jni.TdApi.AuthorizationStateWaitTdlibParameters;
import it.tdlight.jni.TdApi.SetTdlibParameters;
import it.tdlight.jni.TdApi.TdlibParameters;
import it.tdlight.jni.TdApi.UpdateAuthorizationState;

final class AuthorizationStateWaitTdlibParametersHandler implements GenericUpdateHandler<UpdateAuthorizationState> {

	private final TelegramClient client;
	private final TDLibSettings settings;
	private final ExceptionHandler exceptionHandler;

	public AuthorizationStateWaitTdlibParametersHandler(TelegramClient client,
			TDLibSettings settings,
			ExceptionHandler exceptionHandler) {
		this.client = client;
		this.settings = settings;
		this.exceptionHandler = exceptionHandler;
	}

	@Override
	public void onUpdate(UpdateAuthorizationState update) {
		if (update.authorizationState.getConstructor() == AuthorizationStateWaitTdlibParameters.CONSTRUCTOR) {
			TdlibParameters params = new TdlibParameters();
			params.useTestDc = settings.isUsingTestDatacenter();
			params.databaseDirectory = settings.getDatabaseDirectoryPath().toString();
			params.filesDirectory = settings.getDownloadedFilesDirectoryPath().toString();
			params.useFileDatabase = settings.isFileDatabaseEnabled();
			params.useChatInfoDatabase = settings.isChatInfoDatabaseEnabled();
			params.useMessageDatabase = settings.isMessageDatabaseEnabled();
			params.useSecretChats = false;
			params.apiId = settings.getApiToken().getApiID();
			params.apiHash = settings.getApiToken().getApiHash();
			params.systemLanguageCode = settings.getSystemLanguageCode();
			params.deviceModel = settings.getDeviceModel();
			params.systemVersion = settings.getSystemVersion();
			params.applicationVersion = settings.getApplicationVersion();
			params.enableStorageOptimizer = settings.isStorageOptimizerEnabled();
			params.ignoreFileNames = settings.isIgnoreFileNames();
			client.send(new SetTdlibParameters(params), ok -> {
				if (ok.getConstructor() == TdApi.Error.CONSTRUCTOR) {
					throw new TelegramError((TdApi.Error) ok);
				}
			}, exceptionHandler);
		}
	}
}
