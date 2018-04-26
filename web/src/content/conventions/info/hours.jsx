/* @flow */
import * as React from 'react'
import moment from 'moment'

import { l } from '../../../localization'
import { Row } from '../../../common/table/row'
import { Font } from '../../../common/font'
import { newlinesToReact } from '../../../util/newlines-to-react'
import type { ConventionExtraInfo } from '../../../model/convention-extra-info'

export type Props = {
  infos: ConventionExtraInfo[],
  todayOnly?: boolean,
}

function format(date: Date): string {
  return moment(date).format(l`h:mma`)
}

function day(date: Date): string {
  return moment(date).format(l`ddd`)
}

function isToday(date: Date): boolean {
  const newDate = new Date(date)
  newDate.setHours(0)
  newDate.setMinutes(0)
  newDate.setSeconds(0)
  newDate.setMilliseconds(0)

  const today = new Date()
  today.setHours(0)
  today.setMinutes(0)
  today.setSeconds(0)
  today.setMilliseconds(0)

  return newDate.getTime() === today.getTime()
}

export function HoursInfo({ infos, todayOnly }: Props) {
  try {
    const hoursInfo = infos.find(({ title }) => title === 'Hours')
    if (hoursInfo && hoursInfo.info) {
      const hours = JSON.parse(hoursInfo.info)
      if (todayOnly) {
        const todayHours = hours.find(([start, end]) => isToday(start))
        if (todayHours) {
          const [start, end] = todayHours
          return <Row title={<Font smallCaps>{l`Today's hours`}</Font>} value={l`${format(start)} - ${format(end)}`} />
        }
      } else {
        const hoursText = newlinesToReact(
          hours.map(([start, end]) => l`${day(start)} ${format(start)} - ${format(end)}`).join('\n')
        )
        return <Row title={<Font smallCaps>{l`Hours`}</Font>} value={hoursText} />
      }
    }
  } catch(_) {}
  return null
}