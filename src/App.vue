<template>
  <div id="app">
    <InterventionComponent v-if="interventionType=='briefintervention'"/>
    <DecisionAidComponent v-if="interventionType=='decisionaid'"/>
  </div>
</template>

<script>
import InterventionComponent from './components/InterventionComponent.vue'
import DecisionAidComponent from './components/DecisionAidComponent.vue'

export default {
  name: 'App',
  components: {
    InterventionComponent,
    DecisionAidComponent
  },
  data: function() {
    let interventionType = process.env.VUE_APP_ALCOHOL_INTERVENTION.toLowerCase();
    return {
      interventionType: interventionType
    }
  }
}
</script>
