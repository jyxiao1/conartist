'use strict';
import React, { Component } from 'react';
import { ScrollView } from 'react-native';
import SalesPerType from './sales-per-type';
import SalesPerDesign from './sales-per-design';
import { views } from '../../styles'

export default class Stats extends Component {
  render() {
    return (
      <ScrollView style={[views.flex, views.paper]}>
        <SalesPerDesign products={this.props.screenProps.data.products} records={this.props.screenProps.data.records} />
        <SalesPerType products={this.props.screenProps.data.products} records={this.props.screenProps.data.records}/>
      </ScrollView>
    )
  }
}
