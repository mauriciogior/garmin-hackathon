/**
 * Copyright (C) 2014 Garmin International Ltd.
 * Subject to Garmin SDK License Agreement and Wearables Application Developer Agreement.
 */
package com.garmin.android.apps.connectiq.sample;

import java.util.List;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.ConnectIQ.ConnectIQListener;
import com.garmin.android.connectiq.ConnectIQ.IQApplicationEventListener;
import com.garmin.android.connectiq.ConnectIQ.IQDeviceEventListener;
import com.garmin.android.connectiq.ConnectIQ.IQMessageStatus;
import com.garmin.android.connectiq.ConnectIQ.IQSdkErrorStatus;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.IQDevice.IQDeviceStatus;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;

public class MainActivity extends Activity implements OnClickListener {

    private static final String sTAG = "ConnectIQSample";

    private ConnectIQ mConnectIQ;
    private TextView  mSdkStatusText;
    private TextView  mConnectionStatusText;
    private TextView  mDevicesText;
    private EditText  mMessageInput;
    private Button    mSendMessage;

    private IQDevice mDevice;
    private IQApp    mApp;

    /**
     * Listener for SDK specific events.
     */
    ConnectIQListener listener = new ConnectIQListener() {

        /**
         * Received when the SDK is ready for additional method calls after calling initialize().
         */
        @Override
        public void onSdkReady() {
            mSdkStatusText.setText(String.format(getString(R.string.initialized_format), mConnectIQ.getAdbPort()));

            /**
             * Retrieve a list of available (aka currently connected via Garmin Connect Mobile) to display
             * to the user.
             */
            List<IQDevice> devicelist = mConnectIQ.getAvailableDevices();

            if (devicelist.size() == 0) {
                mDevicesText.setText(R.string.no_paired_devices);
            } else {
                StringBuilder builder = new StringBuilder();
                for (IQDevice device : devicelist) {
                    builder.append(device.getFriendlyName());
                    builder.append("\r\n");
                }
                mDevicesText.setText(builder.toString());
            }

            /**
             * Retrieves a list of paired ConnectIQ devices.  This will return a device even if it is not
             * currently connected but is paired with the Garmin Connect Mobile application.  This allows
             * us to register for events to be notified when a device connects or disconnects.
             */
            List<IQDevice> deviceList = mConnectIQ.getPairedDevices();

            StringBuilder builder = new StringBuilder();
            for (IQDevice device : deviceList) {

                /**
                 * Register for event for each device.   This will allow us to receive connect / disconnect
                 * notifications for the devices.  This can be useful if wanting to display information
                 * regarding the currently connected device.
                 */
                mConnectIQ.registerForEvents(device, eventListener, mApp, appEventListener);

                builder.append(device.getFriendlyName());
                builder.append("\r\n");
            }

            mDevicesText.setText(builder.toString());

            /**
             * Check the connection status.  This is necessary because our call
             * to registerForEvents will only notify us of changes from the devices
             * current state.  So if it is already connected when we register for
             * events, we will not be notified that it is connected.
             *
             * For this sample we are just going to deal with the first device
             * from the list, but it is probably better to look at the status
             * for each device if multiple and possibly display a UI for the
             * user to select which device they want to use if multiple are
             * connected.
             */
            IQDevice device = deviceList.get(0);
            try {
                IQDeviceStatus status = mConnectIQ.getStatus(device);
                updateStatus(status);

                mSendMessage.setEnabled(status == IQDeviceStatus.CONNECTED);
                mMessageInput.setEnabled(status == IQDeviceStatus.CONNECTED);
            } catch (IllegalStateException e) {
                Log.e(sTAG, "Illegal state calling getStatus", e);
            } catch (ServiceUnavailableException e) {
                Log.e(sTAG, "Service Unavailable", e);
            }
        }

        /**
         * Called if the SDK failed to initialize.  Inspect IQSdkErrorStatus for specific
         * reason initialization failed.
         */
        @Override
        public void onInitializeError(IQSdkErrorStatus status) {
            mSdkStatusText.setText(status.toString());
        }

        /**
         * Called when the ConnectIQ::shutdown() method is called.  ConnectIQ is a singleton so
         * any call to shutdown() will uninitialize the SDK for all references.
         */
        @Override
        public void onSdkShutDown() {
            mSdkStatusText.setText("Shut Down");
        }
    };

    /**
     * Listener for receiving device specific events.
     */
    IQDeviceEventListener eventListener = new IQDeviceEventListener() {
        @Override
        public void onDeviceStatusChanged(IQDevice device, IQDeviceStatus newStatus) {

            updateStatus(newStatus);
            mSendMessage.setEnabled(newStatus == IQDeviceStatus.CONNECTED);
            mMessageInput.setEnabled(newStatus == IQDeviceStatus.CONNECTED);

        }
    };

    /**
     * Listener for receiving events from applications on a device.
     */
    IQApplicationEventListener appEventListener = new IQApplicationEventListener() {

        @Override
        public void onMessageReceived(IQDevice device, IQApp fromApp, List<Object> messageData, IQMessageStatus status) {
            StringBuilder builder = new StringBuilder();
            for (Object obj : messageData) {
                if (obj instanceof String) {
                    builder.append((String)obj);
                } else {
                    builder.append("Non string object received");
                }
                builder.append("\r\n");
            }

            displayMessage(builder.toString());
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mSdkStatusText = (TextView)findViewById(R.id.sdkstatus);
        mConnectionStatusText = (TextView)findViewById(R.id.connectionstatus);
        mDevicesText = (TextView)findViewById(R.id.devices);
        mMessageInput = (EditText)findViewById(R.id.message);
        mSendMessage = (Button)findViewById(R.id.sendMessage);
        mSendMessage.setOnClickListener(this);

        // Get an instance of ConnectIQ that does BLE simulation over ADB to the simulator.
        mConnectIQ = ConnectIQ.getInstance(ConnectIQ.IQCommProtocol.SIMULATED_BLE);
        mApp = new IQApp("", "Sample App", 1);
    }

    @Override
    public void onResume() {
        super.onResume();

        /**
         * Initializes the SDK.  This must be done before making any calls that will communicate with
         * a Connect IQ device.
         */
        mConnectIQ.initialize(this, true, listener);

        /**
         * We cannot do anything here to call any APIs.   We need to wait and do any additional things once the onSdkReady() call
         * is made on the listener.
         */
    }

    @Override
    public void onPause() {
        super.onPause();

        /**
         * Shutdown the SDK so resources and listeners can be released.
         */
        if (isFinishing()) {
            mConnectIQ.shutdown();
        } else {
            /**
             * Unregister for all events.  This is good practice to clean up to
             * allow the SDK to free resources and not listen for events that
             * no one is interested in.
             *
             * We do not call this if we are shutting down because the shutdown
             * method will call this for us during the clean up process.
             */
            mConnectIQ.unregisterAllForEvents();
        }
    }

    /**
     * When the device sends us a message we will just display a toast notification
     */
    private void displayMessage(String message) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
    }

    @Override
    public void onClick(View v) {
        /**
         * Send the message to the device.  Here we will check the return status and just display a toast
         * with the details if there is an error.  Depending on the error, a message could be displayed to
         * the user to attempt to correct any issues before trying again.
         */
        IQMessageStatus status = mConnectIQ.sendMessage(mDevice, mApp, mMessageInput.getText().toString());
        if (status != IQMessageStatus.SUCCESS) {
            displayMessage(String.format(getString(R.string.message_send_error_format), status.name()));
        } else {
            displayMessage(getString(R.string.message_sent));
            mMessageInput.setText("");
        }
    }

    private void updateStatus(IQDeviceStatus newStatus) {
        switch(newStatus) {
            case CONNECTED:
                mConnectionStatusText.setText(R.string.connection_status_connected);
                break;
            case NOT_CONNECTED:
                mConnectionStatusText.setText(R.string.connection_status_not_connected);
                break;
            case NOT_PAIRED:
                mConnectionStatusText.setText(R.string.connection_status_not_paired);
                break;
            case UNKNOWN:
                mConnectionStatusText.setText(R.string.connection_status_unknown);
                break;
        }
    }
}
