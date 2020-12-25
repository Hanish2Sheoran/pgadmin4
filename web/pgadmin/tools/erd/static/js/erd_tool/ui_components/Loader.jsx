/////////////////////////////////////////////////////////////
//
// pgAdmin 4 - PostgreSQL Tools
//
// Copyright (C) 2013 - 2020, The pgAdmin Development Team
// This software is released under the PostgreSQL Licence
//
//////////////////////////////////////////////////////////////

import React from 'react';

export default function Loader({message, autoEllipsis=false}) {
  if(message || message == '') {
    return (
      <div className="pg-sp-container">
        <div className="pg-sp-content">
          <div className="row">
            <div className="col-12 pg-sp-icon"></div>
          </div>
          <div className="row"><div className="col-12 pg-sp-text">{message}{autoEllipsis ? '...':''}</div></div>
        </div>
      </div>
    );
  } else {
    return null;
  }
}
