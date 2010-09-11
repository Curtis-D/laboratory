package net.fortytwo.iptools;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.util.Random;

/**
 * User: josh
 * Date: Sep 10, 2010
 * Time: 11:06:08 AM
 */
class UdpExperiments {
    private static final Random RANDOM = new Random();

    private final InetAddress receiverAddress;
    private final int receiverPort;
    private final DatagramSocket socket;

    public UdpExperiments(final InetAddress receiverAddress,
                          final int receiverPort) throws SocketException {
        this.receiverAddress = receiverAddress;
        this.receiverPort = receiverPort;
        this.socket = new DatagramSocket();
    }

    public void simpleSend() throws IOException {
        send("Hello world!".getBytes());
    }

    // Beijing --> EC2: <= 23000 or so
    // Beijing --> Flux: <= 23000 or so
    public void testMesssageSize() throws IOException {
        for (int i = 22000; i < 65000; i += 1000) {
            String msg = randomString(i);
            send(msg.getBytes());
            try {
                Thread.currentThread().sleep(1000);
            } catch (InterruptedException e) {
                throw new IOException(e);
            }
        }
    }

    private void send(final byte[] data) throws IOException {
        DatagramPacket packet = new DatagramPacket(data, data.length, receiverAddress, receiverPort);
        socket.send(packet);
    }

    public static void main(final String[] args) {

        try {
            //testLocalReceiver();
            testRemoteReceiver();
        } catch (Throwable t) {
            t.printStackTrace(System.err);
            System.exit(1);
        }
    }

    private static void testLocalReceiver() throws Exception {
        int receiverPort = 8006;

        final UdpReceiver b = new UdpReceiver(receiverPort);
        new Thread(new Runnable() {
            public void run() {
                try {
                    b.start();
                } catch (IOException e) {
                    e.printStackTrace(System.err);
                }
            }
        }).start();

        UdpExperiments t = new UdpExperiments(InetAddress.getLocalHost(), receiverPort);
        t.simpleSend();
        b.stop();
    }

    private static void testRemoteReceiver() throws Exception {
        //InetAddress address = InetAddress.getByName("fortytwo.net");
        InetAddress address = InetAddress.getByName("flux.franz.com");
        //int port = 9990;
        int port = 9995;

        UdpExperiments t = new UdpExperiments(address, port);
        //t.simpleSend();
        t.testMesssageSize();
    }

    ////////////////////////////////////

    private static String randomString(final int length) {
        byte[] b = new byte[length];
        for (int i = 0; i < length; i++) {
            b[i] = (byte) (35 + RANDOM.nextInt(56));
        }
        return new String(b);
    }
}