/* @flow */
import * as React from 'react'
import { SignUp } from './signup'
import type { Props as SignUpProps } from './signup'
import type { Props as BasicProps } from './basic'

import S from './index.css'

export type Props = SignUpProps

export function Dialog(props: Props) {
  let dialog: React.Node;
  
  switch (props.name) {
    case 'signup':
      dialog = <SignUp {...props} />;
      break
  }

  return (
    <div className={S.backdrop}>
      { dialog }
    </div>
  )
}
