import React from 'react'

function StatCard({icon,stat,title}) {
  return (
    <div className='flex p-[1%] gap-4 shadow-xl justify-center w-50 h-30 items-center rounded-2xl border border-gray-300'>
        <div className='flex justify-between'>
            <img src={icon} alt="icon" className='rounded-2xl h-18' />
        </div>
        <div className='mt-3'>
            <h1 className='text-4xl font-bold'>{stat}</h1>
            <h1 className='text-sm text-gray-500'>{title}</h1>
        </div>      
    </div>
  )
}

export default StatCard
