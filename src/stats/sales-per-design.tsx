'use strict';
import * as React from 'react';
import { Subheader, SelectField, MenuItem, Drawer, IconButton, AppBar, RaisedButton } from 'material-ui';
import Settings from 'material-ui/svg-icons/action/settings'
import Close from 'material-ui/svg-icons/navigation/close'
import StackedBarChart from './chart/stacked-bar-chart';
import { saveAs } from 'file-saver';

import { Record, ProductTypes, Colors, Products, empty } from '../types';

type Props = {
  products: Products;
  records: Record[];
};
type State = {
  type: keyof ProductTypes | 'All';
  settings: boolean;
};

export default class SalesPerDesign extends React.Component<Props, State> {
  state: State = {
    type: 'All',
    settings: false
  };
  private get bars(): { [key: string]: { [key in keyof ProductTypes]: number } } {
    return this.props.records
      .filter(record => this.state.type === 'All' || this.state.type === record.type)
      .reduce((p, n) => this.reduceBars(p, n), {} as { [key: string]: { [key in keyof ProductTypes]: number } });
  }
  private get legend(): { [key: string]: { color: string, name: string } } {
    return Object.keys(this.props.products)
      .reduce((obj: { [key: string]: { color: string, name: string } }, key: keyof ProductTypes) => ({ ...obj, [key]: { color: Colors[key], name: ProductTypes[key] }}), {})
  }

  private reduceBars(bars: { [key: string]: { [key in keyof ProductTypes]: number } }, record: Record): { [key: string]: { [key in keyof ProductTypes]: number } } {
    const updated = { ...bars };
    for(let product of record.products) {
      updated[product] = updated[product] || empty(0);
      ++updated[product][record.type];
    }
    return updated;
  }

  private typeChange(_: __MaterialUI.TouchTapEvent, __: number, type: keyof ProductTypes | 'All') {
    this.setState({ type });
  }

  private save(): void {
    const data = this.props.records
      .reduce((p, n) => this.reduceBars(p, n), {} as { [key: string]: { [key in keyof ProductTypes]: number } })
    const blob = new Blob([
      `Design,Total,${Object.keys(this.props.products).map((_: keyof ProductTypes) => ProductTypes[_]).join(',')}\n` +
      Object.keys(data).map(
        key => `${key},${Object.keys(data[key]).reduce((_, p: keyof ProductTypes) => _ + data[key][p], 0)},${Object.keys(this.props.products).map((_: keyof ProductTypes) => data[key][_]).join(',')}`
      ).join('\n')
    ]);
    saveAs(blob, 'sales-per-design.csv', true)
  }

  render() {
    return (
      <div style={{ position: 'relative'}}>
        <Subheader style={{ fontSize: '16px', fontFamily: 'Roboto,sans-serif' }}>Sales Per Design</Subheader>
        <IconButton
          style={{ position: 'absolute', top: 0, right: 10 }}
          onTouchTap={() => this.setState({ settings: true })}>
          <Settings />
        </IconButton>
        <StackedBarChart yLabel='Sales' bars={this.bars} legend={this.legend}/>
        <Drawer
          open={this.state.settings}
          openSecondary
          width='100%'
          style={{display: 'flex'}}>
          <AppBar
            title='Sales Per Design Settings'
            iconElementLeft={<IconButton><Close /></IconButton>}
            onLeftIconButtonTouchTap={() => this.setState({settings: false})} />
          <div style={{padding: 16}}>
            <SelectField
              floatingLabelText='Product Type'
              value={this.state.type}
              onChange={(event, index, value: keyof ProductTypes | 'All') => this.typeChange(event, index, value)}>
              { ['All', ...Object.keys(this.props.products)].map((type: keyof ProductTypes | 'All', i) =>
                <MenuItem key={i} value={type} primaryText={type === 'All' ? 'All' : ProductTypes[type]} />
              ) }
            </SelectField>
          </div>
          <div style={{padding: 16}}>
            <RaisedButton label='Export All' primary onTouchTap={() => this.save()}/>
          </div>
        </Drawer>
      </div>
    )
  }
};
