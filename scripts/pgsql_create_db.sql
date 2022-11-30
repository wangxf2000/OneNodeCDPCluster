CREATE ROLE scm LOGIN PASSWORD 'cloudera';
CREATE DATABASE scm OWNER scm ENCODING 'UTF8';

CREATE ROLE rman LOGIN PASSWORD 'cloudera';
CREATE DATABASE rman OWNER rman ENCODING 'UTF8';

CREATE ROLE hue LOGIN PASSWORD 'cloudera';
CREATE DATABASE hue OWNER hue ENCODING 'UTF8';

CREATE ROLE hive LOGIN PASSWORD 'cloudera';
CREATE DATABASE metastore OWNER hive ENCODING 'UTF8';

CREATE ROLE oozie LOGIN PASSWORD 'cloudera';
CREATE DATABASE oozie OWNER oozie ENCODING 'UTF8';

CREATE ROLE ranger LOGIN PASSWORD 'cloudera';
CREATE DATABASE ranger OWNER ranger ENCODING 'UTF8';

ALTER DATABASE metastore SET standard_conforming_strings=off;
ALTER DATABASE oozie SET standard_conforming_strings=off;


CREATE ROLE efm LOGIN PASSWORD 'cloudera';
CREATE DATABASE efm OWNER efm ENCODING 'UTF8';

CREATE ROLE nifireg LOGIN PASSWORD 'cloudera';
CREATE DATABASE nifireg OWNER nifireg ENCODING 'UTF8';

CREATE ROLE registry LOGIN PASSWORD 'cloudera';
CREATE DATABASE registry OWNER registry ENCODING 'UTF8';


CREATE ROLE streamsmsgmgr LOGIN PASSWORD 'cloudera';
CREATE DATABASE streamsmsgmgr OWNER streamsmsgmgr ENCODING 'UTF8';

CREATE ROLE rangerkms LOGIN PASSWORD 'cloudera';
CREATE DATABASE rangerkms OWNER rangerkms ENCODING 'UTF8';

CREATE ROLE ssb_admin LOGIN PASSWORD 'cloudera';
CREATE DATABASE ssb_admin OWNER ssb_admin ENCODING 'UTF8';

CREATE ROLE ssb_mve LOGIN PASSWORD 'cloudera';
CREATE DATABASE ssb_mve OWNER ssb_mve ENCODING 'UTF8';
