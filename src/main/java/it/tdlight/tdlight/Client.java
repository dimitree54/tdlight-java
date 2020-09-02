package it.tdlight.tdlight;

import it.tdlight.tdlib.NativeClient;
import it.tdlight.tdlib.TdApi.Object;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.locks.ReentrantLock;
import java.util.concurrent.locks.StampedLock;

/**
 * Interface for interaction with TDLib.
 */
public class Client extends NativeClient implements TelegramClient {
	private long clientId;
	private final ReentrantLock receiveLock = new ReentrantLock();
	private final StampedLock executionLock = new StampedLock();
	private volatile Long stampedLockValue;

	/**
	 * Creates a new TDLib client.
	 */
	public Client() {
		try {
			Init.start();
		} catch (Throwable throwable) {
			throwable.printStackTrace();
			System.exit(1);
		}
		this.clientId = createNativeClient();
	}

	@Override
	public void send(Request request) {
		if (this.executionLock.isWriteLocked()) {
			throw new IllegalStateException("ClientActor is destroyed");
		}

		nativeClientSend(this.clientId, request.getId(), request.getFunction());
	}

	private final long[][] eventIds = new long[2][];
	private final Object[][] events = new Object[2][];

	@Override
	public List<Response> receive(double timeout, int eventsSize, boolean receiveResponses, boolean receiveUpdates) {
		return Arrays.asList(this.receive(timeout, eventsSize, receiveResponses, receiveUpdates, false));
	}

	private Response[] receive(double timeout, int eventsSize, boolean receiveResponses, boolean receiveUpdates, boolean singleResponse) {
		if (this.executionLock.isWriteLocked()) {
			throw new IllegalStateException("ClientActor is destroyed");
		}
		if (!(receiveResponses && receiveUpdates)) {
			throw new IllegalArgumentException("The variables receiveResponses and receiveUpdates must be both true, because you are using the original TDLib!");
		}
		int group = (singleResponse ? 0b1 : 0b0);

		if (eventIds[group] == null) {
			eventIds[group] = new long[eventsSize];
		} else {
			Arrays.fill(eventIds[group], 0);
		}
		if (events[group] == null) {
			events[group] = new Object[eventsSize];
		} else {
			Arrays.fill(events[group], null);
		}
		if (eventIds[group].length != eventsSize || events[group].length != eventsSize) {
			throw new IllegalArgumentException("EventSize can't change over time!"
					+ " Previous: " + eventIds[group].length + " Current: " + eventsSize);
		}

		if (this.receiveLock.isLocked()) {
			throw new IllegalThreadStateException("Thread: " + Thread.currentThread().getName() + " trying receive incoming updates but shouldn't be called simultaneously from two different threads!");
		}

		int resultSize;
		this.receiveLock.lock();
		try {
			resultSize = nativeClientReceive(this.clientId, eventIds[group], events[group], timeout);
		} finally {
			this.receiveLock.unlock();
		}

		Response[] responses = new Response[resultSize];

		for (int i = 0; i < resultSize; i++) {
			responses[i] = new Response(eventIds[group][i], events[group][i]);
		}

		return responses;
	}

	@Override
	public Response receive(double timeout, boolean receiveResponses, boolean receiveUpdates) {
		if (this.executionLock.isWriteLocked()) {
			throw new IllegalStateException("ClientActor is destroyed");
		}
		if (!(receiveResponses && receiveUpdates)) {
			throw new IllegalArgumentException("The variables receiveResponses and receiveUpdates must be both true, because you are using the original TDLib!");
		}

		Response[] responses = receive(timeout, 1, receiveResponses, receiveUpdates, true);

		if (responses.length != 0) {
			return responses[0];
		}

		return null;
	}

	@Override
	public Response execute(Request request) {
		if (this.executionLock.isWriteLocked()) {
			throw new IllegalStateException("ClientActor is destroyed");
		}

		Object object = nativeClientExecute(request.getFunction());
		return new Response(0, object);
	}

	@Override
	public void destroyClient() {
		stampedLockValue = this.executionLock.tryWriteLock();
		destroyNativeClient(this.clientId);
	}

	@Override
	public void initializeClient() {
		this.executionLock.tryUnlockWrite();
		stampedLockValue = null;
		this.clientId = createNativeClient();
	}
}
