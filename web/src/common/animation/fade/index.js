/* @flow */
import * as React from 'react'
import S from './index.css'

export type Props<E: React.ElementType> = {
  className?: string,
  children?: ?React.Element<E>,
}

type State<E: React.ElementType> = {
  previousChildren: ?React.Element<E>,
  children: ?React.Element<E>,
  key: boolean,
}

export class Fade<E: React.ElementType> extends React.Component<Props<E>, State<E>> {
  static getDerivedStateFromProps({ children }: Props<E>, state: State<E>) {
    if (children !== state.children) {
      return {
        previousChildren: state.children ? React.cloneElement(state.children) : null,
        children: children || null,
        key: !state.key,
      }
    } else {
      return null;
    }
  }

  animationTimer: ?TimeoutID

  constructor(props: Props<E>) {
    super(props)
    this.animationTimer = null
    this.state = {
      previousChildren: null,
      children: props.children ? React.cloneElement(props.children) : null,
      key: false,
    }
  }

  componentWillUnmount() {
    if (this.animationTimer !== null) {
      clearTimeout(this.animationTimer)
    }
  }

  componentDidUpdate() {
    if (this.animationTimer !== null) {
      clearTimeout(this.animationTimer)
    }
    if (this.state.previousChildren) {
      this.animationTimer = setTimeout(() => {
        this.setState({ previousChildren: null })
        this.animationTimer = null
      }, 200)
    }
  }

  render() {
    const { className, children } = this.props
    const { previousChildren, key } = this.state

    return (
      <div className={`${S.container} ${className || ''}`}>
        <div className={`${S.fade} ${key ? S.visible : ''}`}>
          { key ? children : previousChildren }
        </div>
        <div className={`${S.fade} ${!key ? S.visible : ''}`}>
          { key ? previousChildren : children }
        </div>
      </div>
    )
  }
}
