#!/bin/bash

mongo --quiet xxx <<QUOTATION

ticket = { officer: "Kristen Ree" , location: "Walmart parking lot", vehicle_plate: "Virginia 5566",  offense: "Parked in no parking zone", date: "2010/08/15"}

ticket

db.tickets.save(ticket)

db.tickets.find()

db.tickets.find({location:"Walmart parking lot"})

db.tickets.find({location:/walmart/i})

QUOTATION

