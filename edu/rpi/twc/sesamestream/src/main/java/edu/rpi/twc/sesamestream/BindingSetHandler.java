package edu.rpi.twc.sesamestream;

import org.openrdf.query.BindingSet;

/**
* @author Joshua Shinavier (http://fortytwo.net)
*/
public interface BindingSetHandler {
    void handle(BindingSet result);
}
