class Analysis < ActiveRecord::Base
	
	belongs_to :game
	has_one :analysis_script, dependent: :destroy
	has_one :reduction_script, dependent: :destroy
	has_one :subgame_script, dependent: :destroy
	has_one :dominance_script, dependent: :destroy
	has_one :pbs, dependent: :destroy

	scope :queueable, where(status: "pending").order('created_at ASC').limit(5)
	scope :active, where(status: %w(queued running))
	def fail(message)
    	update_attributes(error_message: message[0..255], status: 'failed')
    	requeue
  	end	

  	def requeue
    	AnalysisRequeuer.perform_in(5.minutes,self)
  	end

  	def queue_as(jid)
    	update_attributes(job_id: jid, status: 'queued') if status == 'pending'
  	end

  	def start
    	update_attributes(status: 'running') if status == 'queued'
  	end

  	def process
	    if %w(queued running).include?(status)
	      ActiveRecord::Base.transaction do
	        update_attributes(status: 'processing')
	      end
	      AnalysisDataParser.perform_async(self)
	    end
  	end
end