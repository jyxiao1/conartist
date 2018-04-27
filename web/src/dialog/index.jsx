/* @flow */
import * as React from 'react'
import { SignUp } from './signup'
import { SignIn } from './signin'
import { ChangePassword } from './change-password'
import type { Props as SignUpProps } from './signup'
import type { Props as SignInProps } from './signin'
import type { Props as ChangePasswordProps } from './change-password'

import S from './index.css'

export type Props = SignUpProps | SignInProps | ChangePasswordProps

export function Dialog(props: Props) {
  let dialog: React.Node;

  switch (props.name) {
    case 'signup':
      dialog = <SignUp {...props} />
      break
    case 'signin':
      dialog = <SignIn {...props} />
      break
    case 'change-password':
      dialog = <ChangePassword {...props} />
      break
  }

  return (
    <div className={S.backdrop}>
      { dialog }
    </div>
  )
}
