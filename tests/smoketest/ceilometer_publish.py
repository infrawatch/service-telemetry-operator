#!/usr/bin/env python

import datetime
import sys

from oslo_config import cfg
from oslo_utils import netutils
from oslo_messaging import opts as oslo_opts

from ceilometer import opts as ceilo_opts
from ceilometer.publisher import messaging
from ceilometer.event import models as event
from ceilometer import sample

from ceilometer.publisher import utils

CREATE_DT = datetime.datetime.utcnow().isoformat()
# Following is real and complete metric and event data sent by OpenStack
# instance after running following actions:
# $ openstack image delete cirros ; sleep 5
# $ openstack image create "cirros" \
# $     --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 \
# $     --container-format bare --public
EVENTS = [
    {"message_id": "b6f075ce-3c69-4cd1-b581-ad2c8e40a4ce",
     "event_type": "image.delete",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"],
         ["project_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["user_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["resource_id", 1, "fb2bbe17-24fd-4487-99c3-d4c5ef279550"],
         ["name", 1, "cirros"],
         ["status", 1, "deleted"],
         ["created_at", 4, CREATE_DT],
         ["deleted_at", 4, CREATE_DT],
         ["size", 2, 13287936]
     ],
     "raw": {},
     "message_signature": "42b976a9eae32b1d0cd055f1262f9cdab88a0e1ad7b89e11d7e3775881d38451"
     },
    {"message_id": "49d16489-411d-4b9b-9a6c-0b29c7a2416a",
     "event_type": "image.create",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"],
         ["project_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["user_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["resource_id", 1, "693d53eb-2b24-4761-87e4-2ffabc1cf410"],
         ["name", 1, "cirros"],
         ["status", 1, "queued"],
         ["created_at", 4, CREATE_DT]
     ],
     "raw": {},
     "message_signature": "9bde7e9f06ee5811c06b1b8397bc5c6a48849c075f6ae7e02727719f6ac0de18"
     },
    {"message_id": "b1570a8b-87f6-485a-afa6-16a738d56417",
     "event_type": "image.update",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"],
         ["project_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["user_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["resource_id", 1, "693d53eb-2b24-4761-87e4-2ffabc1cf410"],
         ["name", 1, "cirros"],
         ["status", 1, "saving"],
         ["created_at", 4, CREATE_DT]
     ],
     "raw": {},
     "message_signature": "b3f526c9eda45fb2f7c801dcac7a902dffb813ec671399a834140768929d21d0"
     },
    {"message_id": "d37fa610-49c1-47b7-a47d-4a04cede9581",
     "event_type": "image.prepare",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"]
     ],
     "raw": {},
     "message_signature": "353797f14ac15f1bd2228696a97caf8d4d54b15b0b6d587ae0447528a8b25d01"
     },
    {"message_id": "49cb5cc8-fd50-444e-9abc-f3df6d9eb8ce",
     "event_type": "image.activate",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"]
     ],
     "raw": {},
     "message_signature": "74f170fd3499f4f84d8af40df1eb0e167e4b2dbaf5665d975452ffe0c0a94373"
     },
    {"message_id": "fc26a59c-7a13-45d2-bd78-ee35ecbb002a",
     "event_type": "image.upload",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"],
         ["project_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["user_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["resource_id", 1, "693d53eb-2b24-4761-87e4-2ffabc1cf410"],
         ["name", 1, "cirros"],
         ["status", 1, "active"],
         ["created_at", 4, CREATE_DT],
         ["size", 2, 13287936]
     ],
     "raw": {},
     "message_signature": "caac0eee38bb1e74c7479173796f17c1f241b4387f509e3a0a8deb7d7cf5c5b0"
     },
    {"message_id": "634de968-2bbb-4e55-a1fd-9fa123ac3423",
     "event_type": "image.update",
     "generated": CREATE_DT,
     "traits": [
         ["service", 1, "image.localhost"],
         ["project_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["user_id", 1, "f7a5d2ac23aa43bb844c6e1cd873c48c"],
         ["resource_id", 1, "693d53eb-2b24-4761-87e4-2ffabc1cf410"],
         ["name", 1, "cirros"],
         ["status", 1, "active"],
         ["created_at", 4, CREATE_DT],
         ["size", 2, 13287936]
     ],
     "raw": {},
     "message_signature": "aeca548756f1b1e44a2829bb54540850f210563c878982c58ed35879d198a2be"
     }
]
METRICS = [
    {"source": "openstack",
     "counter_name": "image.size",
     "counter_type": "gauge",
     "counter_unit": "B",
     "counter_volume": 13287936,
     "user_id": None,
     "project_id": "f7a5d2ac23aa43bb844c6e1cd873c48c",
     "resource_id": "693d53eb-2b24-4761-87e4-2ffabc1cf410",
     "timestamp": CREATE_DT,
     "resource_metadata": {
         "id": "693d53eb-2b24-4761-87e4-2ffabc1cf410",
         "name": "cirros",
         "status": "deleted",
         "created_at": CREATE_DT,
         "updated_at": CREATE_DT,
         "min_disk": 0,
         "min_ram": 0,
         "protected": False,
         "checksum": "ee1eca47dc88f4879d8a229cc70a07c6",
         "owner": "f7a5d2ac23aa43bb844c6e1cd873c48c",
         "disk_format": "qcow2",
         "container_format": "bare",
         "size": 13287936,
         "virtual_size": None,
         "is_public": True,
         "visibility": "public",
         "properties": {},
         "tags": [],
         "deleted": True,
         "deleted_at": CREATE_DT,
         "event_type": "image.delete",
         "host": "image.localhost"
     },
     "message_id": "be1a6e28-9b72-11ea-b865-5254006bcbae",
     "monotonic_time": None, "message_signature": "d2b4b04e2c80e481079da30dfdd138a8072b64d90b025c8b3e1e6b4191a6fc1f"
     },
    {"source": "openstack",
     "counter_name": "image.size",
     "counter_type": "gauge",
     "counter_unit": "B",
     "counter_volume": 13287936,
     "user_id": None,
     "project_id": "f7a5d2ac23aa43bb844c6e1cd873c48c",
     "resource_id": "f297d2f9-168d-49d4-a33c-b68f4a4d5a48",
     "timestamp": CREATE_DT,
     "resource_metadata": {
         "id": "f297d2f9-168d-49d4-a33c-b68f4a4d5a48",
         "name": "cirros",
         "status": "active",
         "created_at": CREATE_DT,
         "updated_at": CREATE_DT,
         "min_disk": 0,
         "min_ram": 0,
         "protected": False,
         "checksum": "ee1eca47dc88f4879d8a229cc70a07c6",
         "owner": "f7a5d2ac23aa43bb844c6e1cd873c48c",
         "disk_format": "qcow2",
         "container_format": "bare",
         "size": 13287936,
         "virtual_size": None,
         "is_public": True,
         "visibility": "public",
         "properties": {},
         "tags": [],
         "deleted": False,
         "deleted_at": None,
         "os_glance_importing_to_stores": [],
         "os_glance_failed_import": [],
         "event_type": "image.upload",
         "host": "image.localhost"
     },
     "message_id": "c2fc49f2-9b72-11ea-ad76-5254006bcbae",
     "monotonic_time": None,
     "message_signature": "8352ad8b3ea90fee918a19bbbd55bf9d522d0d10caa0bf25d9a2a0ca63832d3e"
     },
    {"source": "openstack",
     "counter_name": "image.size",
     "counter_type": "gauge",
     "counter_unit": "B",
     "counter_volume": 13287936,
     "user_id": None,
     "project_id": "f7a5d2ac23aa43bb844c6e1cd873c48c",
     "resource_id": "f297d2f9-168d-49d4-a33c-b68f4a4d5a48",
     "timestamp": CREATE_DT,
     "resource_metadata": {
         "id": "f297d2f9-168d-49d4-a33c-b68f4a4d5a48",
         "name": "cirros",
         "status": "active",
         "created_at": CREATE_DT,
         "updated_at": CREATE_DT,
         "min_disk": 0,
         "min_ram": 0,
         "protected": False,
         "checksum": "ee1eca47dc88f4879d8a229cc70a07c6",
         "owner": "f7a5d2ac23aa43bb844c6e1cd873c48c",
         "disk_format": "qcow2",
         "container_format": "bare",
         "size": 13287936,
         "virtual_size": None,
         "is_public": True,
         "visibility": "public",
         "properties": {},
         "tags": [],
         "deleted": False,
         "deleted_at": None,
         "event_type": "image.update",
         "host": "image.localhost"
     },
     "message_id": "c301498e-9b72-11ea-a1b1-5254006bcbae",
     "monotonic_time": None,
     "message_signature": "adc6b894f69dbfc372be707594433c2cbcc67a1a3b0b34ba4e054f4ed8f9e832"
     }
]


def publish_data(metering_connection, events_connection):
    '''Connects to given QDR passed by argument (default '127.0.0.1:5672')
    and sends sample metric and event data to the bus.
    '''
    conf = cfg.ConfigOpts()
    for opts in [oslo_opts, ceilo_opts]:
        for group, options in opts.list_opts():
            conf.register_opts(list(options),
                               group=None if group == "DEFAULT" else group)
    # override default configuration according to overcloud
    conf.set_override('notify_address_prefix', '', group='oslo_messaging_amqp')
    conf.set_override('control_exchange', 'ceilometer')

    try:
        metric_publisher = messaging.SampleNotifierPublisher(
            conf, netutils.urlsplit(metering_connection))
        event_publisher = messaging.EventNotifierPublisher(
            conf, netutils.urlsplit(events_connection))
    except Exception as ex:
        print(f'Failed to connect to QDR ({url}) due to {ex}')
        sys.exit(1)

    for evt in EVENTS:
        itm = event.Event(message_id=evt['message_id'],
                          event_type=evt['event_type'],
                          generated=evt['generated'],
                          traits=[event.Trait(*tr) for tr in evt['traits']],
                          raw=evt['raw'])
        topic = conf.publisher_notifier.event_topic
        print(f'Sending event to {topic}: '
              f'{utils.message_from_event(itm, conf.publisher.telemetry_secret)}')
        try:
            event_publisher.publish_events([itm])
        except Exception as ex:
            print(f'Failed to send event due to {ex}')
            sys.exit(1)

    for metr in METRICS:
        itm = sample.Sample(name=metr['counter_name'],
                            type=metr['counter_type'],
                            unit=metr['counter_unit'],
                            volume=metr['counter_volume'],
                            user_id=metr['user_id'],
                            project_id=metr['project_id'],
                            resource_id=metr['resource_id'],
                            timestamp=metr['timestamp'],
                            resource_metadata=metr['resource_metadata'])
        topic = conf.publisher_notifier.metering_topic
        print(f'Sending metric to {topic}: '
              f'{utils.meter_message_from_counter(itm, conf.publisher.telemetry_secret)}')
        try:
            metric_publisher.publish_samples([itm])
        except Exception as ex:
            print(f'Failed to send metric due to {ex}')
            sys.exit(1)


if __name__ == '__main__':
    qdr_connection = sys.argv[1] if len(sys.argv) > 1 else '127.0.0.1:5672'
    metering_setting = sys.argv[2] if len(sys.argv) > 2 else 'driver=amqp&topic=cloud1-metering'
    events_setting = sys.argv[3] if len(sys.argv) > 3 else 'driver=amqp&topic=cloud1-event'

    metering_connection = f'notifier://{qdr_connection}/?{metering_setting}'
    events_connection = f'notifier://{qdr_connection}/?{events_setting}'
    publish_data(metering_connection, events_connection)
