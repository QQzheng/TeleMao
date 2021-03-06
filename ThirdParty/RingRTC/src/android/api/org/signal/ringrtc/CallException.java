/*
 *
 *  Copyright (C) 2019 Signal Messenger, LLC.
 *  All rights reserved.
 *
 *  SPDX-License-Identifier: GPL-3.0-only
 *
 */

package org.signal.ringrtc;

/**
* A simple exception class that can be thrown by any of the {@link
* org.signal.ringrtc.CallConnection} class methods.
*
* @see SignalMessageRecipient
*/
public class CallException extends Exception {
  public CallException() {
  }

  public CallException(String detailMessage) {
    super(detailMessage);
  }

  public CallException(String detailMessage, Throwable throwable) {
    super(detailMessage, throwable);
  }

  public CallException(Throwable throwable) {
    super(throwable);
  }
}
